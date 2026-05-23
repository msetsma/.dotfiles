#!/usr/bin/env python3
import csv
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import unicodedata
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import quote


USAGE = """Usage:
  entra user <user-upn-or-id> [--direct|--transitive] [--tsv|--fzf|--interactive] [--full] [--color=auto|always|never]
  entra group <group-display-name-or-id> [--direct|--transitive] [--tsv|--fzf|--interactive] [--full] [--color=auto|always|never]
  entra reports [user-upn-or-id|initial-query] [--direct|--transitive] [--tsv] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra users [initial-query] [--direct|--transitive] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra groups [initial-query] [--direct|--transitive] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra dept [initial-query] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra search [initial-query] [--direct|--transitive] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra search-groups [initial-query] [--direct|--transitive] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]

Output:
  Default mode prints a readable, colorized terminal table.
  --tsv writes a TSV file and prints nothing unless there is an error.
  --interactive, also accepted as --fzf, opens a searchable row picker:
        user -> pick one group -> print that group's users
        group -> pick one user  -> print that user's groups
  users, also accepted as search, opens a searchable user picker, then prints user details and groups.
  groups, also accepted as search-groups, opens a searchable group picker, then prints group details and users.
  dept opens a searchable department picker, then prints department summary and users.
  reports walks the manager/directReports org tree under a user. With no exact user,
  it opens the cached searchable user picker first.

Generated TSV filenames:
  user mode:  <user-upn-slug>.<direct|transitive>.groups.tsv
  group mode: <group-name-slug>_<first-8-of-group-id>.<direct|transitive>.users.tsv
  reports:    <user-upn-slug>.<direct|transitive>.reports.tsv

Notes:
  - Defaults to --transitive, so nested group membership is included.
  - --direct returns only objects assigned directly to the user/group.
  - --transitive returns direct assignments plus nested membership.
  - For reports, --direct returns only direct reports and --transitive walks
    every reporting level below the starting user.
  - For users, output is the groups the user belongs to.
  - For groups, output is the user members of the group.
  - For reports, output includes the starting user at LEVEL 0.
  - Defaults to human-readable output on stdout.
  - Human-readable output shows full email addresses and full object ids.
  - Pass --full to show uncapped names in the human-readable output.
  - TSV output always includes full exact values.
  - --interactive/--fzf requires fzf and cannot be combined with --tsv.
  - users/search, groups/search-groups, dept, and picker-based reports require fzf.
  - users/search, groups/search-groups, dept, and picker-based reports cache picker
    lists for 24 hours in the user cache directory.
  - Pass --refresh-cache to rebuild the search cache, or --no-cache to bypass it.
  - Set ENTRA_MEMBERSHIP_CACHE_TTL_SECONDS to change the search cache TTL.
  - Color defaults to auto. Set NO_COLOR=1 or pass --no-color to disable it.
  - If a group display name matches multiple groups, the app prints the matches
    and exits. Re-run with the group id to avoid exporting the wrong group.
  - Requires Azure CLI auth to already be configured. Search pickers require fzf.
"""


class AppError(Exception):
    pass


class GraphError(AppError):
    pass


@dataclass
class Colors:
    reset: str = ""
    bold: str = ""
    dim: str = ""
    red: str = ""
    green: str = ""
    yellow: str = ""
    blue: str = ""
    magenta: str = ""
    cyan: str = ""
    gray: str = ""


@dataclass
class Options:
    target_type: str
    identifier: str = ""
    initial_query: str = ""
    mode: str = "transitive"
    tsv_output: bool = False
    fzf_output: bool = False
    color_mode: str = "auto"
    full_output: bool = False
    name_width_cap: int = 56
    use_cache: bool = True
    refresh_cache: bool = False
    mode_explicit: bool = False


@dataclass
class State:
    user_id: str = ""
    user_display_name: str = ""
    user_upn: str = ""
    group_id: str = ""
    group_display_name: str = ""
    group_mail: str = ""


COLORS = Colors()


def die(message: str) -> None:
    raise AppError(message)


def warn(message: str) -> None:
    print(f"Warning: {message}", file=sys.stderr)


def need_command(command: str) -> None:
    if shutil.which(command) is None:
        die(f"Missing required command: {command}")


def uri_encode(value: str) -> str:
    return quote(value, safe="")


def odata_string_literal(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def is_guid(value: str) -> bool:
    return bool(re.fullmatch(r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}", value))


def looks_like_bad_guid(value: str) -> bool:
    return bool(re.fullmatch(r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}.+", value))


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", value.lower())
    return slug.strip("_")


def cache_dir() -> Path:
    if os.environ.get("XDG_CACHE_HOME"):
        return Path(os.environ["XDG_CACHE_HOME"]) / "entra_membership"
    if os.environ.get("HOME"):
        return Path(os.environ["HOME"]) / ".cache" / "entra_membership"
    return Path(os.environ.get("TMPDIR", "/tmp")) / "entra_membership-cache"


def search_cache_path() -> Path:
    return cache_dir() / "search_users.tsv"


def search_cache_meta_path() -> Path:
    return cache_dir() / "search_users.meta"


def group_search_cache_path() -> Path:
    return cache_dir() / "search_groups_v2.tsv"


def group_search_cache_meta_path() -> Path:
    return cache_dir() / "search_groups_v2.meta"


def report_direct_reports_cache_path() -> Path:
    return cache_dir() / "report_direct_reports_v1.json"


def cache_ttl_seconds() -> int:
    value = os.environ.get("ENTRA_MEMBERSHIP_CACHE_TTL_SECONDS", "86400")
    return int(value) if value.isdigit() else 86400


def cache_is_fresh(meta_file: Path, cache_file: Path) -> bool:
    if not cache_file.is_file() or cache_file.stat().st_size == 0:
        return False
    if not meta_file.is_file() or meta_file.stat().st_size == 0:
        return False
    try:
        created = int(meta_file.read_text().splitlines()[0])
    except (IndexError, ValueError, OSError):
        return False
    age = int(time.time()) - created
    return 0 <= age < cache_ttl_seconds()


def read_tsv(path: Path) -> list[list[str]]:
    with path.open(newline="") as handle:
        return list(csv.reader(handle, delimiter="\t"))


def tsv_value(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def write_tsv(path: Path, rows: list[list[Any]], header: list[str] | None = None) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        if header is not None:
            writer.writerow(header)
        writer.writerows([[tsv_value(value) for value in row] for row in rows])


def save_search_cache(rows: list[list[Any]], cache_file: Path, meta_file: Path) -> None:
    directory = cache_dir()
    try:
        directory.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile("w", delete=False, dir=directory, newline="") as tmp_cache:
            writer = csv.writer(tmp_cache, delimiter="\t", lineterminator="\n")
            writer.writerows([[tsv_value(value) for value in row] for row in rows])
            tmp_cache_path = Path(tmp_cache.name)
        with tempfile.NamedTemporaryFile("w", delete=False, dir=directory) as tmp_meta:
            tmp_meta.write(f"{int(time.time())}\n")
            tmp_meta_path = Path(tmp_meta.name)
        tmp_cache_path.replace(cache_file)
        tmp_meta_path.replace(meta_file)
    except OSError:
        return


def load_report_direct_reports_cache(use_cache: bool, refresh_cache: bool) -> dict[str, Any]:
    if not use_cache or refresh_cache:
        return {}
    cache_file = report_direct_reports_cache_path()
    if not cache_file.is_file() or cache_file.stat().st_size == 0:
        return {}
    try:
        data = json.loads(cache_file.read_text())
    except (json.JSONDecodeError, OSError):
        return {}
    return data if isinstance(data, dict) else {}


def save_report_direct_reports_cache(cache: dict[str, Any]) -> None:
    directory = cache_dir()
    try:
        directory.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile("w", delete=False, dir=directory) as tmp:
            json.dump(cache, tmp, separators=(",", ":"))
            tmp.write("\n")
            tmp_path = Path(tmp.name)
        tmp_path.replace(report_direct_reports_cache_path())
    except OSError:
        return


def report_cache_entry_is_fresh(entry: Any) -> bool:
    if not isinstance(entry, dict):
        return False
    fetched_at = entry.get("fetchedAt")
    children = entry.get("children")
    if not isinstance(fetched_at, int) or not isinstance(children, list):
        return False
    age = int(time.time()) - fetched_at
    return 0 <= age < cache_ttl_seconds()


def graph_get(url: str) -> dict[str, Any]:
    result = subprocess.run(
        ["az", "rest", "--only-show-errors", "--method", "get", "--url", url, "-o", "json"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        raise GraphError(detail or f"az rest failed for {url}")
    try:
        return json.loads(result.stdout or "{}")
    except json.JSONDecodeError as exc:
        raise GraphError(f"az rest returned invalid JSON for {url}: {exc}") from exc


def graph_post(url: str, body: dict[str, Any]) -> dict[str, Any]:
    result = subprocess.run(
        [
            "az",
            "rest",
            "--only-show-errors",
            "--method",
            "post",
            "--url",
            url,
            "--headers",
            "Content-Type=application/json",
            "--body",
            json.dumps(body),
            "-o",
            "json",
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        raise GraphError(detail or f"az rest failed for {url}")
    try:
        return json.loads(result.stdout or "{}")
    except json.JSONDecodeError as exc:
        raise GraphError(f"az rest returned invalid JSON for {url}: {exc}") from exc


def setup_color(color_mode: str) -> Colors:
    if color_mode == "always":
        use_color = True
    elif color_mode == "never":
        use_color = False
    elif color_mode == "auto":
        if os.environ.get("NO_COLOR"):
            use_color = False
        elif os.environ.get("CLICOLOR_FORCE", "0") != "0":
            use_color = True
        else:
            use_color = sys.stdout.isatty()
    else:
        die(f"Invalid color mode: {color_mode}")

    if not use_color:
        return Colors()
    return Colors(
        reset="\033[0m",
        bold="\033[1m",
        dim="\033[2m",
        red="\033[31m",
        green="\033[32m",
        yellow="\033[33m",
        blue="\033[34m",
        magenta="\033[35m",
        cyan="\033[36m",
        gray="\033[90m",
    )


def styled(value: str, *styles: str) -> str:
    prefix = "".join(style for style in styles if style)
    return f"{prefix}{value}{COLORS.reset}" if prefix else value


def print_quick_start() -> None:
    global COLORS
    COLORS = setup_color("auto")

    command_rows = [
        ("entra users [name]", "Search users, then show details and groups"),
        ("entra groups [name]", "Search groups, then show details and users"),
        ("entra dept [name]", "Search departments, then show users and summary"),
        ("entra reports [name-or-upn]", "Show an org/reporting tree"),
        ("entra user <upn-or-id>", "Show a user's groups"),
        ("entra group <name-or-id>", "Show a group's users"),
    ]
    flag_rows = [
        ("--direct", "Only direct membership or reports"),
        ("--tsv", "Write the generated TSV file"),
        ("--full", "Do not cap long display names"),
        ("--refresh-cache", "Rebuild search picker cache"),
    ]
    examples = [
        'entra users Velasquez',
        'entra dept Engineering',
        'entra groups "Data Science Practice"',
        'entra user person@example.com --direct',
        'entra reports manager@example.com --tsv',
    ]

    print(styled("Entra membership lookup", COLORS.bold, COLORS.cyan))
    print(styled("Search users, groups, and reporting trees from Microsoft Entra ID.", COLORS.dim))
    print()
    print(styled("Common commands", COLORS.bold))
    for command, description in command_rows:
        print(f"  {styled(f'{command:<32}', COLORS.green)} {description}")
    print()
    print(styled("Useful flags", COLORS.bold))
    for flag, description in flag_rows:
        print(f"  {styled(f'{flag:<32}', COLORS.yellow)} {description}")
    print()
    print(styled("Examples", COLORS.bold))
    for example in examples:
        print(f"  {styled(example, COLORS.dim)}")
    print()
    print(f"Run {styled('entra --help', COLORS.cyan)} for the full command reference.")


def clean(value: Any) -> str:
    if value is None or value == "" or value == "None" or value == "null":
        return "-"
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value).replace("\r", "")


def json_scalar(obj: dict[str, Any], key: str) -> str:
    return clean(obj.get(key))


def json_array(obj: dict[str, Any], key: str) -> str:
    value = obj.get(key) or []
    if not isinstance(value, list):
        return clean(value)
    joined = ", ".join(str(item) for item in value if item is not None)
    return joined or "-"


def char_width(char: str) -> int:
    code = ord(char)
    if (
        unicodedata.combining(char)
        or unicodedata.category(char) == "Cf"
        or 0xFE00 <= code <= 0xFE0F
        or 0x1F3FB <= code <= 0x1F3FF
    ):
        return 0
    if 0x1F1E6 <= code <= 0x1F1FF:
        return 1
    if unicodedata.east_asian_width(char) in ("F", "W"):
        return 2
    if 0x1F000 <= code <= 0x1FAFF or 0x2600 <= code <= 0x27BF:
        return 2
    return 1


def display_width(value: Any) -> int:
    total = 0
    join_next = False
    for char in str(value):
        if char == "\u200d":
            join_next = True
            continue
        next_width = char_width(char)
        if join_next and next_width == 2:
            join_next = False
            continue
        join_next = False
        total += next_width
    return total


def fit(value: Any, cap: int, full: bool = False) -> str:
    value = clean(value)
    if full or cap <= 0 or display_width(value) <= cap:
        return value
    out = ""
    used = 0
    join_next = False
    for char in value:
        if char == "\u200d":
            out += char
            join_next = True
            continue
        next_width = char_width(char)
        if join_next and next_width == 2:
            next_width = 0
        join_next = False
        if used + next_width > cap - 3:
            break
        out += char
        used += next_width
    return out + "..."


def terminal_width(default: int = 120) -> int:
    return shutil.get_terminal_size((default, 20)).columns


def cell(value: Any, target: int, color: str = "") -> str:
    value = clean(value)
    pad = max(0, target - display_width(value))
    suffix = COLORS.reset if color else ""
    return color + value + suffix + (" " * pad)


def yn(value: Any) -> str:
    value = clean(value).lower()
    if value == "true":
        return "Y"
    if value == "false":
        return "N"
    return "-"


def bool_color(value: str) -> str:
    return COLORS.green if value == "Y" else COLORS.yellow


def text_color(value: str, default: str) -> str:
    return COLORS.gray if clean(value) == "-" else default


def type_color(value: str) -> str:
    if value == "Unified":
        return COLORS.cyan
    if value == "DynamicMembership":
        return COLORS.magenta
    if value == "-":
        return COLORS.gray
    return ""


def date_value(value: Any) -> str:
    value = clean(value)
    return value if value == "-" else value[:10]


def print_kv(key: str, value: Any) -> None:
    print(f"{COLORS.dim}{key + ':':<15}{COLORS.reset} {value}")


def print_kv_continuation(value: Any) -> None:
    print(f"{COLORS.dim}{'':<15}{COLORS.reset} {value}")


def mode_note(mode: str) -> str:
    return {
        "direct": "direct membership only",
        "transitive": "direct plus nested membership",
    }.get(mode, "unknown membership mode")


def print_mode(mode: str) -> None:
    print_kv("Mode", f"{mode}  # {mode_note(mode)}")


def report_mode_note(mode: str) -> str:
    return {
        "direct": "direct reports only",
        "transitive": "direct reports plus every lower reporting level",
    }.get(mode, "unknown reports mode")


def print_report_mode(mode: str) -> None:
    print_kv("Mode", f"{mode}  # {report_mode_note(mode)}")


def print_group_legend() -> None:
    print(f"\n{COLORS.dim}Group legend:{COLORS.reset} MAIL_EN=mail enabled, SEC_EN=security enabled, TYPE=group type, CREATED=created date. Unified=Microsoft 365 group, DynamicMembership=rule-based membership. Long names are capped unless --full is used. Use --tsv for full exact values.")


def print_user_legend() -> None:
    print(f"\n{COLORS.dim}User legend:{COLORS.reset} ENABLED=account enabled. Long names are capped unless --full is used. Use --tsv for full exact values.")


def print_reports_legend() -> None:
    print(f"\n{COLORS.dim}Reports legend:{COLORS.reset}")
    print(f"  {COLORS.cyan}USER{COLORS.reset} is a tree and is never truncated.")
    print(f"  {COLORS.gray}LEVEL{COLORS.reset}=visible depth, {COLORS.gray}DIRECTS{COLORS.reset}=direct reports.")
    print("  Hidden: missing title or disabled account.")
    print("  Columns reveal as space allows; use --full or --tsv for complete values.")


def print_proxy_addresses(obj: dict[str, Any], full_output: bool) -> None:
    primary_smtp_values: list[str] = []
    smtp_alias_values: list[str] = []
    x500_values: list[str] = []
    other_values: list[str] = []

    for addr in obj.get("proxyAddresses") or []:
        if not addr:
            continue
        lower = str(addr).lower()
        value = str(addr).split(":", 1)[1] if ":" in str(addr) else str(addr)
        if lower.startswith("smtp:"):
            if str(addr).startswith("SMTP:"):
                primary_smtp_values.append(f"{value} (primary)")
            else:
                smtp_alias_values.append(value)
        elif lower.startswith("x500:"):
            x500_values.append(str(addr))
        else:
            other_values.append(str(addr))

    smtp_values = primary_smtp_values + smtp_alias_values
    if not smtp_values and not x500_values and not other_values:
        print_kv("Proxy SMTP", "-")
        return

    if smtp_values:
        print_kv("Proxy SMTP", smtp_values[0])
        for value in smtp_values[1:]:
            print_kv_continuation(value)
    else:
        print_kv("Proxy SMTP", "-")

    if x500_values:
        if full_output:
            print_kv("Proxy X500", x500_values[0])
            for value in x500_values[1:]:
                print_kv_continuation(value)
        else:
            print_kv("Proxy X500", f"{len(x500_values)} legacy Exchange address(es) hidden; pass --full to show")

    if other_values:
        print_kv("Proxy other", other_values[0])
        for value in other_values[1:]:
            print_kv_continuation(value)


def print_user_details(obj: dict[str, Any], full_output: bool) -> None:
    print(f"{COLORS.bold}{COLORS.cyan}User details{COLORS.reset}")
    fields = [
        ("Name", "displayName"),
        ("UPN", "userPrincipalName"),
        ("Mail", "mail"),
        ("ID", "id"),
        ("Enabled", "accountEnabled"),
        ("User type", "userType"),
        ("Title", "jobTitle"),
        ("Department", "department"),
        ("Company", "companyName"),
        ("Office", "officeLocation"),
        ("Employee ID", "employeeId"),
        ("Employee type", "employeeType"),
        ("Mobile", "mobilePhone"),
        ("Manager", "managerDisplayName"),
        ("Manager ID", "managerId"),
    ]
    for label, key in fields:
        print_kv(label, json_scalar(obj, key))
    print_kv("Business", json_array(obj, "businessPhones"))
    for label, key in [
        ("Mail nick", "mailNickname"),
        ("OnPrem UPN", "onPremisesUserPrincipalName"),
        ("OnPrem SAM", "onPremisesSamAccountName"),
        ("OnPrem sync", "onPremisesSyncEnabled"),
        ("Created", "createdDateTime"),
    ]:
        print_kv(label, json_scalar(obj, key))
    print_proxy_addresses(obj, full_output)


def print_group_owners(group_id: str, full_output: bool) -> None:
    encoded = uri_encode(group_id)
    try:
        obj = graph_get(f"https://graph.microsoft.com/v1.0/groups/{encoded}/owners?$select=id,displayName,userPrincipalName,mail&$top=20")
    except GraphError:
        print_kv("Owners", "not available")
        return

    owners = obj.get("value") or []
    if not owners:
        print_kv("Owners", "-")
        return

    limit = len(owners) if full_output else min(len(owners), 5)
    for index, owner in enumerate(owners[:limit]):
        name = clean(owner.get("displayName"))
        detail = clean(owner.get("userPrincipalName") or owner.get("mail") or owner.get("id"))
        if index == 0:
            print_kv("Owners", f"{name} <{detail}>")
        else:
            print_kv_continuation(f"{name} <{detail}>")
    if limit < len(owners):
        print_kv_continuation(f"{len(owners) - limit} more owner(s); pass --full to show first 20")


def print_group_details(obj: dict[str, Any], full_output: bool) -> None:
    print(f"{COLORS.bold}{COLORS.cyan}Group details{COLORS.reset}")
    scalar_fields = [
        ("Name", "displayName"),
        ("Description", "description"),
        ("Mail", "mail"),
        ("Mail nick", "mailNickname"),
        ("ID", "id"),
        ("Mail enabled", "mailEnabled"),
        ("Security", "securityEnabled"),
    ]
    for label, key in scalar_fields:
        print_kv(label, json_scalar(obj, key))
    print_kv("Group types", json_array(obj, "groupTypes"))
    for label, key in [
        ("Visibility", "visibility"),
        ("Assignable", "isAssignableToRole"),
        ("Classification", "classification"),
        ("Created", "createdDateTime"),
        ("Renewed", "renewedDateTime"),
        ("Expires", "expirationDateTime"),
        ("Rule state", "membershipRuleProcessingState"),
        ("Member rule", "membershipRule"),
        ("OnPrem sync", "onPremisesSyncEnabled"),
        ("OnPrem last", "onPremisesLastSyncDateTime"),
        ("OnPrem SID", "onPremisesSecurityIdentifier"),
    ]:
        print_kv(label, json_scalar(obj, key))
    print_kv("Provisioning", json_array(obj, "resourceProvisioningOptions"))
    print_kv("Behavior", json_array(obj, "resourceBehaviorOptions"))
    print_proxy_addresses(obj, full_output)


def sorted_rows(rows: list[list[Any]]) -> list[list[Any]]:
    return sorted(rows, key=lambda row: "\t".join(clean(value).casefold() for value in row))


def format_group_table(rows: list[list[Any]], full_output: bool, name_width_cap: int = 56) -> str:
    formatted = []
    for row in rows:
        padded = list(row) + [""] * (7 - len(row))
        formatted.append([
            fit(padded[0], name_width_cap, full_output),
            clean(padded[1]),
            clean(padded[2]),
            yn(padded[3]),
            yn(padded[4]),
            clean(padded[5]),
            date_value(padded[6]),
        ])

    widths = [
        max([display_width("GROUP")] + [display_width(row[0]) for row in formatted]),
        max([display_width("MAIL")] + [display_width(row[1]) for row in formatted]),
        max([display_width("ID")] + [display_width(row[2]) for row in formatted]),
        7,
        6,
        max([display_width("TYPE")] + [display_width(row[5]) for row in formatted]),
        max([display_width("CREATED")] + [display_width(row[6]) for row in formatted]),
    ]
    lines = [
        "  ".join([
            cell("GROUP", widths[0], COLORS.bold + COLORS.cyan),
            cell("MAIL", widths[1], COLORS.bold + COLORS.cyan),
            cell("ID", widths[2], COLORS.bold + COLORS.cyan),
            cell("MAIL_EN", widths[3], COLORS.bold + COLORS.cyan),
            cell("SEC_EN", widths[4], COLORS.bold + COLORS.cyan),
            cell("TYPE", widths[5], COLORS.bold + COLORS.cyan),
            cell("CREATED", widths[6], COLORS.bold + COLORS.cyan),
        ]),
        "  ".join([cell("-" * width, width, COLORS.dim) for width in widths]),
    ]
    for group, mail, object_id, mail_enabled, security_enabled, group_type, created in formatted:
        lines.append("  ".join([
            cell(group, widths[0]),
            cell(mail, widths[1], text_color(mail, COLORS.blue)),
            cell(object_id, widths[2], COLORS.gray),
            cell(mail_enabled, widths[3], bool_color(mail_enabled)),
            cell(security_enabled, widths[4], bool_color(security_enabled)),
            cell(group_type, widths[5], type_color(group_type)),
            cell(created, widths[6], COLORS.gray),
        ]))
    return "\n".join(lines)


def format_user_table(rows: list[list[Any]], full_output: bool, name_width_cap: int = 56) -> str:
    formatted = []
    for row in rows:
        padded = list(row) + [""] * (7 - len(row))
        formatted.append([
            fit(padded[0], name_width_cap, full_output),
            clean(padded[1]),
            clean(padded[2]),
            clean(padded[3]),
            yn(padded[4]),
            fit(padded[5], name_width_cap, full_output),
            clean(padded[6]),
        ])

    widths = [
        max([display_width("USER")] + [display_width(row[0]) for row in formatted]),
        max([display_width("UPN")] + [display_width(row[1]) for row in formatted]),
        max([display_width("MAIL")] + [display_width(row[2]) for row in formatted]),
        max([display_width("ID")] + [display_width(row[3]) for row in formatted]),
        7,
        max([display_width("MANAGER")] + [display_width(row[5]) for row in formatted]),
        max([display_width("MANAGER_ID")] + [display_width(row[6]) for row in formatted]),
    ]
    lines = [
        "  ".join([
            cell("USER", widths[0], COLORS.bold + COLORS.cyan),
            cell("UPN", widths[1], COLORS.bold + COLORS.cyan),
            cell("MAIL", widths[2], COLORS.bold + COLORS.cyan),
            cell("ID", widths[3], COLORS.bold + COLORS.cyan),
            cell("ENABLED", widths[4], COLORS.bold + COLORS.cyan),
            cell("MANAGER", widths[5], COLORS.bold + COLORS.cyan),
            cell("MANAGER_ID", widths[6], COLORS.bold + COLORS.cyan),
        ]),
        "  ".join([cell("-" * width, width, COLORS.dim) for width in widths]),
    ]
    for user, upn, mail, object_id, enabled, manager, manager_id in formatted:
        lines.append("  ".join([
            cell(user, widths[0]),
            cell(upn, widths[1], text_color(upn, COLORS.blue)),
            cell(mail, widths[2], text_color(mail, COLORS.blue)),
            cell(object_id, widths[3], COLORS.gray),
            cell(enabled, widths[4], bool_color(enabled)),
            cell(manager, widths[5]),
            cell(manager_id, widths[6], COLORS.gray),
        ]))
    return "\n".join(lines)


def report_display_order() -> list[str]:
    return ["LEVEL", "USER", "MAIL", "ID", "TITLE", "DEPT", "DIRECTS"]


def report_required_columns() -> list[str]:
    return ["LEVEL", "USER", "TITLE", "DIRECTS"]


def report_optional_columns() -> list[str]:
    return ["MAIL", "DEPT", "ID"]


def report_column_color(name: str, value: str) -> str:
    if name == "USER":
        return COLORS.bold
    if name == "LEVEL" or name == "ID" or name == "DIRECTS":
        return COLORS.gray
    if name == "MAIL":
        return text_color(value, COLORS.blue)
    if name == "TITLE":
        return text_color(value, COLORS.green)
    if name == "DEPT":
        return text_color(value, COLORS.magenta)
    return ""


def report_table_width(widths: dict[str, int], column_names: list[str]) -> int:
    return sum(widths[name] for name in column_names) + (2 * (len(column_names) - 1))


def report_content_width(records: list[dict[str, str]], name: str) -> int:
    return max([display_width(name)] + [display_width(record[name]) for record in records])


def report_column_width(records: list[dict[str, str]], name: str, minimums: dict[str, int], preferred_caps: dict[str, int], full_output: bool) -> int:
    width = report_content_width(records, name)
    if not full_output and name != "USER":
        width = min(width, preferred_caps.get(name, width))
    return max(width, minimums.get(name, display_width(name)))


def choose_report_columns(records: list[dict[str, str]], minimums: dict[str, int], preferred_caps: dict[str, int], max_width: int, full_output: bool) -> tuple[list[str], dict[str, int]]:
    if full_output:
        column_names = report_display_order()
        widths = {name: report_column_width(records, name, minimums, preferred_caps, full_output) for name in column_names}
        return column_names, widths

    selected = report_required_columns()
    widths = {name: report_column_width(records, name, minimums, preferred_caps, full_output) for name in selected}
    shrink_widths(widths, minimums, max_width, selected)

    for name in report_optional_columns():
        candidate_names = sorted(selected + [name], key=report_display_order().index)
        candidate_widths = dict(widths)
        candidate_widths[name] = report_column_width(records, name, minimums, preferred_caps, full_output)
        shrink_widths(candidate_widths, minimums, max_width, candidate_names)
        if report_table_width(candidate_widths, candidate_names) <= max_width:
            selected = candidate_names
            widths = candidate_widths

    return selected, widths


def shrink_widths(widths: dict[str, int], minimums: dict[str, int], max_width: int, column_names: list[str]) -> None:
    shrink_order = ["TITLE", "MAIL", "DEPT", "ID"]
    total = report_table_width(widths, column_names)
    for name in shrink_order:
        if total <= max_width:
            return
        if name not in widths:
            continue
        available = widths[name] - minimums.get(name, display_width(name))
        if available <= 0:
            continue
        reduction = min(available, total - max_width)
        widths[name] -= reduction
        total -= reduction


def format_reports_table(rows: list[list[Any]], full_output: bool, name_width_cap: int = 48, max_width: int | None = None) -> str:
    max_width = max_width or terminal_width()
    minimums = {"LEVEL": 5, "USER": 18, "MAIL": 16, "ID": 8, "TITLE": 12, "DEPT": 8, "DIRECTS": 7}
    preferred_caps = {"MAIL": 30, "ID": 36, "TITLE": 30, "DEPT": 18}
    records: list[dict[str, str]] = []

    for row in rows:
        padded = list(row) + [""] * (12 - len(row))
        user_value = padded[11] or padded[4]
        record = {
            "LEVEL": clean(padded[0]),
            "USER": clean(user_value),
            "MAIL": clean(padded[6]),
            "ID": clean(padded[3]),
            "TITLE": clean(padded[7]),
            "DEPT": clean(padded[8]),
            "DIRECTS": clean(padded[10]),
        }
        records.append(record)

    column_names, widths = choose_report_columns(records, minimums, preferred_caps, max_width, full_output)

    lines = [
        "  ".join([cell(name, widths[name], COLORS.bold + COLORS.cyan) for name in column_names]),
        "  ".join([cell("-" * widths[name], widths[name], COLORS.dim) for name in column_names]),
    ]
    for record in records:
        lines.append("  ".join([
            cell(record[name] if name == "USER" else fit(record[name], widths[name], full_output), widths[name], report_column_color(name, record[name]))
            for name in column_names
        ]))
    return "\n".join(lines)


def picker_emit(headers: list[str], widths: list[int], rows: list[tuple[list[str], list[str]]]) -> str:
    header_row = [cell(header, width, COLORS.bold + COLORS.cyan) for header, width in zip(headers, widths)]
    rule_row = [cell("-" * min(width, max(4, display_width(header))), width, COLORS.dim) for header, width in zip(headers, widths)]
    lines = ["  ".join(header_row) + "\t__id\t__name\t__value", "  ".join(rule_row) + "\t\t\t"]
    for visible, hidden in rows:
        lines.append("  ".join(visible) + "\t" + "\t".join(hidden))
    return "\n".join(lines) + "\n"


def format_picker_rows(kind: str, rows: list[list[Any]]) -> str:
    input_rows = sorted_rows(rows)
    if kind == "group":
        headers = ["GROUP", "MAIL", "ID", "MAIL_EN", "SEC_EN", "TYPE", "CREATED"]
        widths = [56, 72, 36, 7, 6, 18, 10]
        picker_rows = []
        for row in input_rows:
            padded = list(row) + [""] * (7 - len(row))
            name = fit(padded[0], 56)
            mail = fit(padded[1], 72)
            object_id = clean(padded[2])
            mail_enabled = yn(padded[3])
            security_enabled = yn(padded[4])
            group_type = fit(padded[5], 18)
            created = date_value(padded[6])
            picker_rows.append(([
                cell(name, 56),
                cell(mail, 72, text_color(mail, COLORS.blue)),
                cell(object_id, 36, COLORS.gray),
                cell(mail_enabled, 7, bool_color(mail_enabled)),
                cell(security_enabled, 6, bool_color(security_enabled)),
                cell(group_type, 18, type_color(group_type)),
                cell(created, 10, COLORS.gray),
            ], [object_id, clean(padded[0]), clean(padded[1])]))
        return picker_emit(headers, widths, picker_rows)

    if kind == "user":
        headers = ["USER", "UPN", "MAIL", "ID", "ENABLED"]
        widths = [42, 40, 40, 36, 7]
        picker_rows = []
        for row in input_rows:
            padded = list(row) + [""] * (5 - len(row))
            name = fit(padded[0], 42)
            upn = fit(padded[1], 40)
            mail = fit(padded[2], 40)
            object_id = clean(padded[3])
            enabled = yn(padded[4])
            picker_rows.append(([
                cell(name, 42),
                cell(upn, 40, text_color(upn, COLORS.blue)),
                cell(mail, 40, text_color(mail, COLORS.blue)),
                cell(object_id, 36, COLORS.gray),
                cell(enabled, 7, bool_color(enabled)),
            ], [object_id, clean(padded[0]), clean(padded[1])]))
        return picker_emit(headers, widths, picker_rows)

    if kind == "search_user":
        headers = ["USER", "UPN", "MAIL", "TITLE", "DEPT", "TYPE", "ENABLED"]
        widths = [34, 42, 42, 28, 24, 10, 7]
        picker_rows = []
        for row in input_rows:
            padded = list(row) + [""] * (10 - len(row))
            name = fit(padded[0], 34)
            upn = fit(padded[1], 42)
            mail = fit(padded[2], 42)
            object_id = clean(padded[3])
            enabled = yn(padded[4])
            user_type = fit(padded[5], 10)
            title = fit(padded[6], 28)
            dept = fit(padded[7], 24)
            picker_rows.append(([
                cell(name, 34),
                cell(upn, 42, text_color(upn, COLORS.blue)),
                cell(mail, 42, text_color(mail, COLORS.blue)),
                cell(title, 28),
                cell(dept, 24),
                cell(user_type, 10, COLORS.gray),
                cell(enabled, 7, bool_color(enabled)),
            ], [object_id, clean(padded[0]), clean(padded[1])]))
        return picker_emit(headers, widths, picker_rows)

    if kind == "department":
        headers = ["DEPARTMENT", "USERS", "ENABLED", "DISABLED", "GUESTS", "NO_TITLE", "COMPANIES", "OFFICES"]
        widths = [56, 7, 7, 8, 6, 8, 9, 7]
        picker_rows = []
        for row in rows:
            padded = list(row) + [""] * (9 - len(row))
            department = fit(padded[0], 56)
            key = clean(padded[1])
            users = clean(padded[2])
            enabled = clean(padded[3])
            disabled = clean(padded[4])
            guests = clean(padded[5])
            missing_title = clean(padded[6])
            companies = clean(padded[7])
            offices = clean(padded[8])
            picker_rows.append(([
                cell(department, 56),
                cell(users, 7, COLORS.gray),
                cell(enabled, 7, COLORS.green),
                cell(disabled, 8, COLORS.yellow),
                cell(guests, 6, COLORS.magenta if guests != "0" else COLORS.gray),
                cell(missing_title, 8, COLORS.yellow if missing_title != "0" else COLORS.gray),
                cell(companies, 9, COLORS.gray),
                cell(offices, 7, COLORS.gray),
            ], [key, clean(padded[0])]))
        return picker_emit(headers, widths, picker_rows)

    die(f"unknown picker kind: {kind}")


def run_fzf(input_text: str, prompt: str, header: str, query: str = "") -> str | None:
    args = [
        "fzf",
        "--ansi",
        "--height=90%",
        "--layout=reverse",
        "--border=rounded",
        "--cycle",
        "--exact",
        "--header-lines=2",
        "--no-multi",
        "--pointer=>",
        "--marker=*",
        f"--prompt={prompt}",
        f"--header={header}",
        "--delimiter=\t",
        "--with-nth=1",
    ]
    if query:
        args.append(f"--query={query}")
    result = subprocess.run(args, input=input_text, text=True, stdout=subprocess.PIPE, stderr=None, check=False)
    if result.returncode != 0:
        print("No selection.", file=sys.stderr)
        return None
    return result.stdout.rstrip("\n")


def group_type_value(group: dict[str, Any]) -> str:
    return ";".join(str(value) for value in group.get("groupTypes") or [])


def group_row(group: dict[str, Any]) -> list[Any]:
    return [
        group.get("displayName") or "",
        group.get("mail") or "",
        group.get("id") or "",
        group.get("mailEnabled"),
        group.get("securityEnabled"),
        group_type_value(group),
        group.get("createdDateTime") or "",
    ]


def user_row(user: dict[str, Any]) -> list[Any]:
    return [
        user.get("displayName") or "",
        user.get("userPrincipalName") or "",
        user.get("mail") or "",
        user.get("id") or "",
        user.get("accountEnabled"),
    ]


def empty_manager_details() -> dict[str, str]:
    return {"managerDisplayName": "", "managerId": ""}


def manager_details_from_obj(obj: dict[str, Any]) -> dict[str, str]:
    return {
        "managerDisplayName": obj.get("displayName") or "",
        "managerId": obj.get("id") or "",
    }


def manager_lookup_missing_status(status: int) -> bool:
    return status == 404


def fetch_user_manager_details(user_id: str) -> dict[str, str]:
    if not user_id:
        return empty_manager_details()
    try:
        obj = graph_get(f"https://graph.microsoft.com/v1.0/users/{uri_encode(user_id)}/manager?$select=id,displayName")
    except GraphError:
        return empty_manager_details()
    return manager_details_from_obj(obj)


def chunks(values: list[str], size: int) -> list[list[str]]:
    return [values[index:index + size] for index in range(0, len(values), size)]


def fetch_user_manager_details_batch(user_ids: list[str]) -> dict[str, dict[str, str]]:
    unique_user_ids = list(dict.fromkeys(user_id for user_id in user_ids if user_id))
    managers = {user_id: empty_manager_details() for user_id in unique_user_ids}

    for batch_user_ids in chunks(unique_user_ids, 20):
        request_to_user_id = {str(index): user_id for index, user_id in enumerate(batch_user_ids)}
        body = {
            "requests": [
                {
                    "id": request_id,
                    "method": "GET",
                    "url": f"/users/{uri_encode(user_id)}/manager?$select=id,displayName",
                }
                for request_id, user_id in request_to_user_id.items()
            ]
        }
        try:
            batch = graph_post("https://graph.microsoft.com/v1.0/$batch", body)
        except GraphError as exc:
            warn(f"Manager batch lookup failed; falling back to individual lookups. {exc}")
            for user_id in batch_user_ids:
                managers[user_id] = fetch_user_manager_details(user_id)
            continue

        responses = batch.get("responses") or []
        for response in responses:
            if not isinstance(response, dict):
                continue
            user_id = request_to_user_id.get(str(response.get("id")))
            response_body = response.get("body")
            status = response.get("status")
            if not user_id or not isinstance(response_body, dict) or not isinstance(status, int):
                continue
            if 200 <= status < 300:
                managers[user_id] = manager_details_from_obj(response_body)
            elif not manager_lookup_missing_status(status):
                warn(f"Manager lookup failed for user {user_id}: Graph batch response status {status}")

    return managers


def add_manager_details_to_user_rows(rows: list[list[Any]]) -> list[list[Any]]:
    user_ids = []
    for row in rows:
        padded = list(row) + [""] * (5 - len(row))
        user_id = clean(padded[3])
        if user_id != "-":
            user_ids.append(user_id)

    managers = fetch_user_manager_details_batch(user_ids)
    enriched = []
    for row in rows:
        padded = list(row) + [""] * (5 - len(row))
        user_id = clean(padded[3])
        manager = managers.get(user_id, empty_manager_details())
        enriched.append(padded[:5] + [manager["managerDisplayName"], manager["managerId"]] + padded[5:])
    return enriched


def department_display(value: Any) -> str:
    value = str(value or "").strip()
    return value or "(No department)"


def department_key(value: Any) -> str:
    value = str(value or "").strip()
    return f"department:{value.casefold()}" if value else "missing_department:"


def department_sort_key(row: list[Any]) -> tuple[str, str]:
    display = clean(row[0])
    return ("~" if display == "(No department)" else display.casefold(), display)


def build_department_rows(user_rows: list[list[Any]]) -> list[list[Any]]:
    stats: dict[str, dict[str, Any]] = {}
    for row in user_rows:
        padded = list(row) + [""] * (10 - len(row))
        key = department_key(padded[7])
        stat = stats.setdefault(key, {
            "display": department_display(padded[7]),
            "users": 0,
            "enabled": 0,
            "disabled": 0,
            "guests": 0,
            "missing_title": 0,
            "companies": set(),
            "offices": set(),
        })
        stat["users"] += 1
        if yn(padded[4]) == "N":
            stat["disabled"] += 1
        else:
            stat["enabled"] += 1
        if clean(padded[5]).casefold() == "guest":
            stat["guests"] += 1
        if not str(padded[6] or "").strip():
            stat["missing_title"] += 1
        if str(padded[8] or "").strip():
            stat["companies"].add(str(padded[8]).strip())
        if str(padded[9] or "").strip():
            stat["offices"].add(str(padded[9]).strip())

    rows = [
        [
            stat["display"],
            key,
            stat["users"],
            stat["enabled"],
            stat["disabled"],
            stat["guests"],
            stat["missing_title"],
            len(stat["companies"]),
            len(stat["offices"]),
        ]
        for key, stat in stats.items()
    ]
    return sorted(rows, key=department_sort_key)


def users_for_department(user_rows: list[list[Any]], selected_key: str) -> list[list[Any]]:
    rows = []
    for row in user_rows:
        padded = list(row) + [""] * (10 - len(row))
        if department_key(padded[7]) == selected_key:
            rows.append(padded[:10])
    return rows


def count_values(values: list[Any]) -> list[tuple[str, int]]:
    counts: dict[str, int] = {}
    for value in values:
        cleaned = clean(value)
        if cleaned == "-":
            continue
        counts[cleaned] = counts.get(cleaned, 0) + 1
    return sorted(counts.items(), key=lambda item: (-item[1], item[0].casefold()))


def top_values(values: list[Any], limit: int = 5) -> str:
    counts = count_values(values)
    if not counts:
        return "-"
    return ", ".join(f"{value} ({count})" for value, count in counts[:limit])


def format_department_user_table(rows: list[list[Any]], full_output: bool, name_width_cap: int = 42) -> str:
    formatted = []
    for row in rows:
        padded = list(row) + [""] * (12 - len(row))
        formatted.append([
            fit(padded[0], name_width_cap, full_output),
            fit(padded[8], 30, full_output),
            clean(padded[1]),
            clean(padded[2]),
            clean(padded[3]),
            yn(padded[4]),
            fit(padded[5], name_width_cap, full_output),
            clean(padded[6]),
            fit(padded[10], 24, full_output),
            fit(padded[11], 24, full_output),
        ])

    widths = [
        max([display_width("USER")] + [display_width(row[0]) for row in formatted]),
        max([display_width("TITLE")] + [display_width(row[1]) for row in formatted]),
        max([display_width("UPN")] + [display_width(row[2]) for row in formatted]),
        max([display_width("MAIL")] + [display_width(row[3]) for row in formatted]),
        max([display_width("ID")] + [display_width(row[4]) for row in formatted]),
        7,
        max([display_width("MANAGER")] + [display_width(row[6]) for row in formatted]),
        max([display_width("MANAGER_ID")] + [display_width(row[7]) for row in formatted]),
        max([display_width("COMPANY")] + [display_width(row[8]) for row in formatted]),
        max([display_width("OFFICE")] + [display_width(row[9]) for row in formatted]),
    ]
    lines = [
        "  ".join([
            cell("USER", widths[0], COLORS.bold + COLORS.cyan),
            cell("TITLE", widths[1], COLORS.bold + COLORS.cyan),
            cell("UPN", widths[2], COLORS.bold + COLORS.cyan),
            cell("MAIL", widths[3], COLORS.bold + COLORS.cyan),
            cell("ID", widths[4], COLORS.bold + COLORS.cyan),
            cell("ENABLED", widths[5], COLORS.bold + COLORS.cyan),
            cell("MANAGER", widths[6], COLORS.bold + COLORS.cyan),
            cell("MANAGER_ID", widths[7], COLORS.bold + COLORS.cyan),
            cell("COMPANY", widths[8], COLORS.bold + COLORS.cyan),
            cell("OFFICE", widths[9], COLORS.bold + COLORS.cyan),
        ]),
        "  ".join([cell("-" * width, width, COLORS.dim) for width in widths]),
    ]
    for user, title, upn, mail, object_id, enabled, manager, manager_id, company, office in formatted:
        lines.append("  ".join([
            cell(user, widths[0]),
            cell(title, widths[1], text_color(title, COLORS.green)),
            cell(upn, widths[2], text_color(upn, COLORS.blue)),
            cell(mail, widths[3], text_color(mail, COLORS.blue)),
            cell(object_id, widths[4], COLORS.gray),
            cell(enabled, widths[5], bool_color(enabled)),
            cell(manager, widths[6]),
            cell(manager_id, widths[7], COLORS.gray),
            cell(company, widths[8]),
            cell(office, widths[9]),
        ]))
    return "\n".join(lines)


def search_user_row(user: dict[str, Any]) -> list[Any]:
    return [
        user.get("displayName") or "",
        user.get("userPrincipalName") or "",
        user.get("mail") or "",
        user.get("id") or "",
        user.get("accountEnabled"),
        user.get("userType") or "",
        user.get("jobTitle") or "",
        user.get("department") or "",
        user.get("companyName") or "",
        user.get("officeLocation") or "",
    ]


def collect_paged_rows(url: str, row_builder) -> list[list[Any]]:
    rows: list[list[Any]] = []
    while url:
        page = graph_get(url)
        rows.extend(row_builder(item) for item in page.get("value") or [])
        url = page.get("@odata.nextLink") or ""
    return rows


def resolve_user(identifier: str, state: State) -> None:
    encoded = uri_encode(identifier)
    try:
        obj = graph_get(f"https://graph.microsoft.com/v1.0/users/{encoded}?$select=id,displayName,userPrincipalName,mail")
    except GraphError:
        die(f"User not found: {identifier}. Use the user's full UPN/email address or Entra object id.")

    state.user_id = clean(obj.get("id"))
    state.user_display_name = obj.get("displayName") or ""
    state.user_upn = obj.get("userPrincipalName") or ""
    if state.user_id == "-":
        die(f"User not found: {identifier}")


def resolve_group(identifier: str, state: State) -> None:
    if is_guid(identifier):
        encoded = uri_encode(identifier)
        try:
            obj = graph_get(f"https://graph.microsoft.com/v1.0/groups/{encoded}?$select=id,displayName,mail,mailEnabled,securityEnabled,groupTypes,createdDateTime")
        except GraphError:
            die(f"Group not found: {identifier}. Use a full group object id or exact display name.")
    elif looks_like_bad_guid(identifier):
        die(f"This looks like a group id with extra characters: {identifier}")
    elif re.fullmatch(r"[0-9A-Fa-f]{8,31}", identifier):
        die("Short group id prefixes are not supported. Use the full group id.")
    else:
        filter_value = uri_encode(f"displayName eq {odata_string_literal(identifier)}")
        try:
            result = graph_get(f"https://graph.microsoft.com/v1.0/groups?$filter={filter_value}&$select=id,displayName,mail,mailEnabled,securityEnabled,groupTypes,createdDateTime&$top=50")
        except GraphError:
            die(f"Group lookup failed for: {identifier}")
        matches = result.get("value") or []
        if not matches:
            die(f"No group found with displayName exactly equal to: {identifier}")
        if len(matches) > 1:
            print(f'Multiple groups found for displayName "{identifier}". Re-run with the group id:', file=sys.stderr)
            writer = csv.writer(sys.stderr, delimiter="\t", lineterminator="\n")
            writer.writerow(["displayName", "mail", "id", "mailEnabled", "securityEnabled", "groupTypes", "createdDateTime"])
            for group in matches:
                writer.writerow([tsv_value(value) for value in group_row(group)])
            raise SystemExit(2)
        obj = matches[0]

    state.group_id = clean(obj.get("id"))
    state.group_display_name = obj.get("displayName") or ""
    state.group_mail = obj.get("mail") or ""
    if state.group_id == "-":
        die(f"Group not found: {identifier}")


def pick_group_then_show_users(rows: list[list[Any]], mode: str, state: State, opts: Options) -> None:
    header = (
        f"{COLORS.bold}Search groups:{COLORS.reset} type to filter, Up/Down moves, Enter opens users for the highlighted group, Esc cancels\n"
        f"{COLORS.dim}Group legend:{COLORS.reset} MAIL_EN=mail enabled, SEC_EN=security enabled, TYPE=group type, CREATED=created date; Unified=Microsoft 365 group, DynamicMembership=rule-based membership"
    )
    selected = run_fzf(format_picker_rows("group", rows), "Search groups > ", header)
    if selected is None:
        return
    parts = selected.split("\t")
    group_id = parts[1] if len(parts) > 1 else ""
    if group_id == "__id" or not group_id:
        print("No data row selected.", file=sys.stderr)
        return
    state.group_id = group_id
    state.group_display_name = parts[2] if len(parts) > 2 else ""
    state.group_mail = parts[3] if len(parts) > 3 else ""
    print()
    relationship = "transitiveMembers" if mode == "transitive" else "members"
    write_user_rows_for_group(relationship, "", False, mode, False, state, opts)


def pick_user_then_show_groups(rows: list[list[Any]], mode: str, state: State, opts: Options) -> None:
    header = (
        f"{COLORS.bold}Search users:{COLORS.reset} type to filter, Up/Down moves, Enter opens groups for the highlighted user, Esc cancels\n"
        f"{COLORS.dim}User legend:{COLORS.reset} ENABLED=account enabled"
    )
    selected = run_fzf(format_picker_rows("user", rows), "Search users > ", header)
    if selected is None:
        return
    parts = selected.split("\t")
    user_id = parts[1] if len(parts) > 1 else ""
    if user_id == "__id" or not user_id:
        print("No data row selected.", file=sys.stderr)
        return
    state.user_id = user_id
    state.user_display_name = parts[2] if len(parts) > 2 else ""
    state.user_upn = parts[3] if len(parts) > 3 else ""
    print()
    relationship = "transitiveMemberOf" if mode == "transitive" else "memberOf"
    write_group_rows_for_user(relationship, "", False, mode, False, state, opts)


def user_detail_select_fields() -> str:
    return "id,displayName,userPrincipalName,mail,accountEnabled,userType,jobTitle,department,companyName,officeLocation,employeeId,employeeType,mobilePhone,businessPhones,mailNickname,onPremisesUserPrincipalName,onPremisesSamAccountName,onPremisesSyncEnabled,createdDateTime,proxyAddresses"


def show_selected_user_report(selected_user_id: str, mode: str, state: State, opts: Options) -> None:
    encoded = uri_encode(selected_user_id)
    try:
        obj = graph_get(f"https://graph.microsoft.com/v1.0/users/{encoded}?$select={user_detail_select_fields()}")
    except GraphError:
        die(f"User detail lookup failed for selected user id: {selected_user_id}")
    state.user_id = obj.get("id") or ""
    state.user_display_name = obj.get("displayName") or ""
    state.user_upn = obj.get("userPrincipalName") or ""
    manager = fetch_user_manager_details(state.user_id)
    obj["managerDisplayName"] = manager["managerDisplayName"]
    obj["managerId"] = manager["managerId"]
    print()
    print_user_details(obj, opts.full_output)
    print()
    relationship = "transitiveMemberOf" if mode == "transitive" else "memberOf"
    write_group_rows_for_user(relationship, "", False, mode, False, state, opts)


def load_user_search_rows(use_cache: bool, refresh_cache: bool) -> tuple[list[list[Any]], bool]:
    cache_file = search_cache_path()
    meta_file = search_cache_meta_path()
    if use_cache and not refresh_cache and cache_is_fresh(meta_file, cache_file):
        return read_tsv(cache_file), True

    url = "https://graph.microsoft.com/v1.0/users?$select=id,displayName,userPrincipalName,mail,accountEnabled,userType,jobTitle,department,companyName,officeLocation&$top=999"
    rows = collect_paged_rows(url, search_user_row)
    if use_cache:
        save_search_cache(rows, cache_file, meta_file)
    return rows, False


def search_users(mode: str, initial_query: str, use_cache: bool, refresh_cache: bool, state: State, opts: Options) -> None:
    rows, loaded_from_cache = load_user_search_rows(use_cache, refresh_cache)
    if not rows:
        die("No users returned from Microsoft Graph.")
    cache_state = "hit" if loaded_from_cache else "fresh"
    header = (
        f"{COLORS.bold}Search users:{COLORS.reset} type to filter, Up/Down moves, Enter prints user details and groups, Esc cancels\n"
        f"{COLORS.dim}User legend:{COLORS.reset} ENABLED=account enabled, TYPE=Entra user type, CACHE={cache_state}"
    )
    selected = run_fzf(format_picker_rows("search_user", rows), "Search users > ", header, initial_query)
    if selected is None:
        return
    parts = selected.split("\t")
    user_id = parts[1] if len(parts) > 1 else ""
    if user_id == "__id" or not user_id:
        print("No data row selected.", file=sys.stderr)
        return
    show_selected_user_report(user_id, mode, state, opts)


def print_department_summary(department_name: str, rows: list[list[Any]]) -> None:
    enabled = sum(1 for row in rows if yn(row[4]) != "N")
    disabled = sum(1 for row in rows if yn(row[4]) == "N")
    guests = sum(1 for row in rows if clean(row[7]).casefold() == "guest")
    missing_title = sum(1 for row in rows if clean(row[8]) == "-")
    managers = {clean(row[6]) for row in rows if clean(row[6]) != "-"}
    companies = {clean(row[10]) for row in rows if clean(row[10]) != "-"}
    offices = {clean(row[11]) for row in rows if clean(row[11]) != "-"}

    print(f"{COLORS.bold}{COLORS.cyan}Department details{COLORS.reset}")
    print_kv("Department", department_name)
    print_kv("Users", len(rows))
    print_kv("Enabled", enabled)
    print_kv("Disabled", disabled)
    print_kv("Guests", guests)
    print_kv("Missing title", missing_title)
    print_kv("Managers", len(managers))
    print_kv("Companies", len(companies))
    print_kv("Offices", len(offices))
    print_kv("Top titles", top_values([row[8] for row in rows]))
    print_kv("Top managers", top_values([row[5] for row in rows]))
    print_kv("Top offices", top_values([row[11] for row in rows]))


def search_departments(initial_query: str, use_cache: bool, refresh_cache: bool, opts: Options) -> None:
    rows, loaded_from_cache = load_user_search_rows(use_cache, refresh_cache)
    if not rows:
        die("No users returned from Microsoft Graph.")

    department_rows = build_department_rows(rows)
    if not department_rows:
        die("No departments found in Microsoft Graph user data.")

    cache_state = "hit" if loaded_from_cache else "fresh"
    header = (
        f"{COLORS.bold}Search departments:{COLORS.reset} type to filter, Up/Down moves, Enter prints department users, Esc cancels\n"
        f"{COLORS.dim}Department legend:{COLORS.reset} NO_TITLE=users with no job title, CACHE={cache_state}"
    )
    selected = run_fzf(format_picker_rows("department", department_rows), "Search departments > ", header, initial_query)
    if selected is None:
        return
    parts = selected.split("\t")
    selected_key = parts[1] if len(parts) > 1 else ""
    department_name = parts[2] if len(parts) > 2 else ""
    if selected_key == "__id" or not selected_key:
        print("No data row selected.", file=sys.stderr)
        return

    department_users = users_for_department(rows, selected_key)
    department_users = add_manager_details_to_user_rows(department_users)
    print()
    print_department_summary(department_name, department_users)
    print()
    print(format_department_user_table(sorted_rows(department_users), opts.full_output, opts.name_width_cap))
    print_user_legend()


def show_selected_group_report(selected_group_id: str, mode: str, state: State, opts: Options) -> None:
    encoded = uri_encode(selected_group_id)
    full_url = f"https://graph.microsoft.com/v1.0/groups/{encoded}?$select=id,displayName,description,mail,mailNickname,mailEnabled,securityEnabled,groupTypes,visibility,classification,createdDateTime,renewedDateTime,expirationDateTime,membershipRule,membershipRuleProcessingState,onPremisesSyncEnabled,onPremisesLastSyncDateTime,onPremisesSecurityIdentifier,proxyAddresses,resourceProvisioningOptions,resourceBehaviorOptions,isAssignableToRole"
    safe_url = f"https://graph.microsoft.com/v1.0/groups/{encoded}?$select=id,displayName,description,mail,mailNickname,mailEnabled,securityEnabled,groupTypes,visibility,classification,createdDateTime,renewedDateTime,expirationDateTime,membershipRule,membershipRuleProcessingState,onPremisesSyncEnabled,onPremisesLastSyncDateTime,onPremisesSecurityIdentifier,proxyAddresses,resourceProvisioningOptions,resourceBehaviorOptions"
    try:
        obj = graph_get(full_url)
    except GraphError:
        try:
            obj = graph_get(safe_url)
        except GraphError:
            die(f"Group detail lookup failed for selected group id: {selected_group_id}")

    state.group_id = obj.get("id") or ""
    state.group_display_name = obj.get("displayName") or ""
    state.group_mail = obj.get("mail") or ""
    print()
    print_group_details(obj, opts.full_output)
    print_group_owners(state.group_id, opts.full_output)
    print()
    relationship = "transitiveMembers" if mode == "transitive" else "members"
    write_user_rows_for_group(relationship, "", False, mode, False, state, opts)


def load_group_search_rows(use_cache: bool, refresh_cache: bool) -> tuple[list[list[Any]], bool]:
    cache_file = group_search_cache_path()
    meta_file = group_search_cache_meta_path()
    if use_cache and not refresh_cache and cache_is_fresh(meta_file, cache_file):
        return read_tsv(cache_file), True

    url = "https://graph.microsoft.com/v1.0/groups?$select=id,displayName,mail,mailEnabled,securityEnabled,groupTypes,createdDateTime&$top=999"
    rows = collect_paged_rows(url, group_row)
    if use_cache:
        save_search_cache(rows, cache_file, meta_file)
    return rows, False


def search_groups(mode: str, initial_query: str, use_cache: bool, refresh_cache: bool, state: State, opts: Options) -> None:
    rows, loaded_from_cache = load_group_search_rows(use_cache, refresh_cache)
    if not rows:
        die("No groups returned from Microsoft Graph.")
    cache_state = "hit" if loaded_from_cache else "fresh"
    header = (
        f"{COLORS.bold}Search groups:{COLORS.reset} type to filter, Up/Down moves, Enter prints group details and users, Esc cancels\n"
        f"{COLORS.dim}Group legend:{COLORS.reset} MAIL_EN=mail enabled, SEC_EN=security enabled, TYPE=group type, CREATED=created date, CACHE={cache_state}"
    )
    selected = run_fzf(format_picker_rows("group", rows), "Search groups > ", header, initial_query)
    if selected is None:
        return
    parts = selected.split("\t")
    group_id = parts[1] if len(parts) > 1 else ""
    if group_id == "__id" or not group_id:
        print("No data row selected.", file=sys.stderr)
        return
    show_selected_group_report(group_id, mode, state, opts)


def report_user_select_fields() -> str:
    return "id,displayName,userPrincipalName,mail,accountEnabled,userType,jobTitle,department,companyName,officeLocation,employeeId,employeeType,createdDateTime"


def fetch_report_user_json(selected_user_id: str) -> dict[str, Any]:
    encoded = uri_encode(selected_user_id)
    return graph_get(f"https://graph.microsoft.com/v1.0/users/{encoded}?$select={report_user_select_fields()}")


def report_max_workers() -> int:
    value = os.environ.get("ENTRA_REPORTS_MAX_WORKERS", "4")
    try:
        parsed = int(value)
    except ValueError:
        parsed = 4
    return max(1, min(parsed, 8))


def fetch_direct_report_users(manager: dict[str, Any]) -> list[dict[str, Any]]:
    manager_id = manager.get("id") or ""
    if not manager_id:
        return []
    children: list[dict[str, Any]] = []
    url = f"https://graph.microsoft.com/v1.0/users/{uri_encode(manager_id)}/directReports/microsoft.graph.user?$select={report_user_select_fields()}&$top=999"
    while url:
        page = graph_get(url)
        for child in page.get("value") or []:
            if isinstance(child, dict):
                children.append(child)
        url = page.get("@odata.nextLink") or ""
    return children


def cached_direct_report_users(manager_id: str, report_cache: dict[str, Any], use_cache: bool, refresh_cache: bool) -> list[dict[str, Any]] | None:
    if not use_cache or refresh_cache:
        return None
    entry = report_cache.get(manager_id)
    if not report_cache_entry_is_fresh(entry):
        return None
    children = entry.get("children") if isinstance(entry, dict) else None
    if not isinstance(children, list):
        return None
    return [child for child in children if isinstance(child, dict)]


def cache_direct_report_users(manager_id: str, children: list[dict[str, Any]], report_cache: dict[str, Any], use_cache: bool) -> bool:
    if not use_cache:
        return False
    report_cache[manager_id] = {"fetchedAt": int(time.time()), "children": children}
    return True


def report_queue_item(user: dict[str, Any], level: int, manager_id: str = "", manager_display_name: str = "") -> dict[str, Any]:
    return {
        "id": user.get("id") or "",
        "level": level,
        "managerId": manager_id,
        "managerDisplayName": manager_display_name,
        "displayName": user.get("displayName") or "",
        "userPrincipalName": user.get("userPrincipalName") or "",
        "mail": user.get("mail") or "",
        "jobTitle": user.get("jobTitle") or "",
        "department": user.get("department") or "",
        "accountEnabled": "" if user.get("accountEnabled") is None else user.get("accountEnabled"),
    }


def report_has_title(user: dict[str, Any]) -> bool:
    return bool(clean(user.get("jobTitle")).strip("- "))


def report_is_enabled(user: dict[str, Any]) -> bool:
    return yn(user.get("accountEnabled")) != "N"


def report_is_visible(user: dict[str, Any]) -> bool:
    return report_has_title(user) and report_is_enabled(user)


def report_sort_key(user: dict[str, Any]) -> tuple[str, str]:
    return (clean(user.get("displayName")).lower(), clean(user.get("id")).lower())


def report_display_name(user: dict[str, Any]) -> str:
    return clean(user.get("displayName") or user.get("mail") or user.get("id"))


def build_visible_report_rows(root_id: str, users: dict[str, dict[str, Any]], children_by_manager: dict[str, list[dict[str, Any]]]) -> list[list[Any]]:
    rows: list[list[Any]] = []

    def visible_children(parent_id: str) -> list[dict[str, Any]]:
        visible: list[dict[str, Any]] = []
        for child in sorted(children_by_manager.get(parent_id, []), key=report_sort_key):
            child_id = child.get("id") or ""
            if not child_id:
                continue
            if report_is_visible(child):
                visible.append(child)
            else:
                visible.extend(visible_children(child_id))
        return visible

    def append_row(user: dict[str, Any], visible_level: int, tree_name: str) -> None:
        rows.append([
            visible_level,
            user.get("managerId") or "",
            user.get("managerDisplayName") or "",
            user.get("id") or "",
            user.get("displayName") or "",
            user.get("userPrincipalName") or "",
            user.get("mail") or "",
            user.get("jobTitle") or "",
            user.get("department") or "",
            user.get("accountEnabled"),
            user.get("directReportCount", ""),
            tree_name,
        ])

    def walk(user: dict[str, Any], visible_level: int, prefix: str, is_last: bool, is_root: bool = False) -> None:
        name = report_display_name(user)
        if is_root:
            tree_name = name
            child_prefix = ""
        else:
            connector = "└── " if is_last else "├── "
            tree_name = f"{prefix}{connector}{name}"
            child_prefix = prefix + ("    " if is_last else "│   ")

        append_row(user, visible_level, tree_name)
        children = visible_children(user.get("id") or "")
        for index, child in enumerate(children):
            walk(child, visible_level + 1, child_prefix, index == len(children) - 1)

    root = users.get(root_id)
    if root and report_is_visible(root):
        walk(root, 0, "", True, True)
    elif root:
        children = visible_children(root_id)
        for index, child in enumerate(children):
            walk(child, 0, "", index == len(children) - 1)

    return rows


def write_report_rows_for_user(out: str, tsv_output: bool, mode: str, state: State, opts: Options) -> None:
    try:
        root_json = fetch_report_user_json(state.user_id)
    except GraphError:
        die(f"User detail lookup failed for reports root: {state.user_id}")

    state.user_display_name = root_json.get("displayName") or ""
    state.user_upn = root_json.get("userPrincipalName") or ""

    report_cache = load_report_direct_reports_cache(opts.use_cache, opts.refresh_cache)
    cache_dirty = False
    frontier = [report_queue_item(root_json, 0)]
    visited: set[str] = set()
    users: dict[str, dict[str, Any]] = {}
    children_by_manager: dict[str, list[dict[str, Any]]] = {}

    def add_children(current: dict[str, Any], raw_children: list[dict[str, Any]], next_frontier: list[dict[str, Any]]) -> None:
        current_id = current.get("id") or ""
        current_level = int(current.get("level") or 0)
        children = [
            report_queue_item(child, current_level + 1, current_id, current.get("displayName") or "")
            for child in raw_children
        ]
        current["directReportCount"] = len(children)
        children_by_manager[current_id] = children
        next_frontier.extend(children)

    while frontier:
        next_frontier: list[dict[str, Any]] = []
        fetch_targets: list[dict[str, Any]] = []
        for current in frontier:
            current_id = current.get("id") or ""
            if not current_id or current_id in visited:
                continue
            visited.add(current_id)
            users[current_id] = current

            current_level = int(current.get("level") or 0)
            expand_children = not (mode == "direct" and current_level >= 1)
            if not expand_children:
                current["directReportCount"] = ""
                children_by_manager[current_id] = []
                continue

            cached_children = cached_direct_report_users(current_id, report_cache, opts.use_cache, opts.refresh_cache)
            if cached_children is not None:
                add_children(current, cached_children, next_frontier)
            else:
                fetch_targets.append(current)

        if fetch_targets:
            with ThreadPoolExecutor(max_workers=report_max_workers()) as executor:
                futures = {executor.submit(fetch_direct_report_users, current): current for current in fetch_targets}
                for future in as_completed(futures):
                    current = futures[future]
                    current_id = current.get("id") or ""
                    try:
                        raw_children = future.result()
                    except GraphError:
                        die(f"Direct reports lookup failed for user: {current.get('displayName', '')} <{current.get('userPrincipalName', '')}>")
                    cache_dirty = cache_direct_report_users(current_id, raw_children, report_cache, opts.use_cache) or cache_dirty
                    add_children(current, raw_children, next_frontier)

        frontier = next_frontier

    rows = build_visible_report_rows(state.user_id, users, children_by_manager)
    hidden_disabled = sum(1 for user in users.values() if not report_is_enabled(user))
    hidden_missing_title = sum(1 for user in users.values() if report_is_enabled(user) and not report_has_title(user))
    if cache_dirty:
        save_report_direct_reports_cache(report_cache)

    if tsv_output and out:
        tsv_rows = [[row[0], row[1], row[2], row[3], row[4], row[6], row[7], row[8], row[10]] for row in rows]
        write_tsv(Path(out), tsv_rows, ["level", "managerId", "managerDisplayName", "id", "displayName", "mail", "jobTitle", "department", "directReportCount"])
        return
    if tsv_output:
        die("Internal error: TSV output path was not set")

    root_visible = report_is_visible(users.get(state.user_id, {}))
    report_count = max(0, len(rows) - 1) if root_visible else len(rows)
    max_depth = max([int(row[0]) for row in rows], default=0)
    print(f"{COLORS.bold}{COLORS.cyan}User report hierarchy{COLORS.reset}")
    print_kv("Root", state.user_display_name)
    print_kv("ID", state.user_id)
    print_report_mode(mode)
    print_kv("Shown", len(rows))
    print_kv("Reports", report_count)
    hidden_notes = []
    if hidden_missing_title:
        hidden_notes.append(f"{hidden_missing_title} missing title")
    if hidden_disabled:
        hidden_notes.append(f"{hidden_disabled} disabled")
    if hidden_notes:
        print_kv("Hidden", ", ".join(hidden_notes))
    print_kv("Max depth", max_depth)
    print()
    print(format_reports_table(rows, opts.full_output, 48))
    print_reports_legend()


def search_reports(mode: str, initial_query: str, use_cache: bool, refresh_cache: bool, tsv_output: bool, state: State, opts: Options) -> None:
    rows, loaded_from_cache = load_user_search_rows(use_cache, refresh_cache)
    if not rows:
        die("No users returned from Microsoft Graph.")
    cache_state = "hit" if loaded_from_cache else "fresh"
    header = (
        f"{COLORS.bold}Search users for reports:{COLORS.reset} type to filter, Up/Down moves, Enter prints report hierarchy, Esc cancels\n"
        f"{COLORS.dim}User legend:{COLORS.reset} ENABLED=account enabled, TYPE=Entra user type, CACHE={cache_state}"
    )
    selected = run_fzf(format_picker_rows("search_user", rows), "Search reports root > ", header, initial_query)
    if selected is None:
        return
    parts = selected.split("\t")
    user_id = parts[1] if len(parts) > 1 else ""
    if user_id == "__id" or not user_id:
        print("No data row selected.", file=sys.stderr)
        return
    state.user_id = user_id
    state.user_display_name = parts[2] if len(parts) > 2 else ""
    state.user_upn = parts[3] if len(parts) > 3 else ""
    out = ""
    if tsv_output:
        slug = slugify(state.user_upn)
        out = f"{slug or 'user'}.{mode}.reports.tsv"
    else:
        print()
    write_report_rows_for_user(out, tsv_output, mode, state, opts)


def write_group_rows_for_user(relationship: str, out: str, tsv_output: bool, mode: str, fzf_output: bool, state: State, opts: Options) -> None:
    url = f"https://graph.microsoft.com/v1.0/users/{uri_encode(state.user_id)}/{relationship}/microsoft.graph.group?$select=id,displayName,mail,mailEnabled,securityEnabled,groupTypes,createdDateTime&$top=999"
    rows = collect_paged_rows(url, group_row)

    if tsv_output and out:
        write_tsv(Path(out), sorted_rows(rows), ["displayName", "mail", "id", "mailEnabled", "securityEnabled", "groupTypes", "createdDateTime"])
        return
    if tsv_output:
        die("Internal error: TSV output path was not set")
    if fzf_output:
        pick_group_then_show_users(rows, mode, state, opts)
        return

    print(f"{COLORS.bold}{COLORS.cyan}User group membership{COLORS.reset}")
    print_kv("User", state.user_display_name)
    print_kv("UPN", state.user_upn)
    print_mode(mode)
    print_kv("Groups", len(rows))
    print()
    print(format_group_table(sorted_rows(rows), opts.full_output, opts.name_width_cap))
    print_group_legend()


def write_user_rows_for_group(relationship: str, out: str, tsv_output: bool, mode: str, fzf_output: bool, state: State, opts: Options) -> None:
    url = f"https://graph.microsoft.com/v1.0/groups/{uri_encode(state.group_id)}/{relationship}/microsoft.graph.user?$select=id,displayName,userPrincipalName,mail,accountEnabled&$top=999"
    rows = collect_paged_rows(url, user_row)

    if fzf_output:
        pick_user_then_show_groups(rows, mode, state, opts)
        return

    rows = add_manager_details_to_user_rows(rows)

    if tsv_output and out:
        write_tsv(
            Path(out),
            sorted_rows(rows),
            ["displayName", "userPrincipalName", "mail", "id", "accountEnabled", "managerDisplayName", "managerId"],
        )
        return
    if tsv_output:
        die("Internal error: TSV output path was not set")

    print(f"{COLORS.bold}{COLORS.cyan}Group user membership{COLORS.reset}")
    print_kv("Group", state.group_display_name)
    if state.group_mail:
        print_kv("Mail", state.group_mail)
    print_kv("ID", state.group_id)
    print_mode(mode)
    print_kv("Users", len(rows))
    print()
    print(format_user_table(sorted_rows(rows), opts.full_output, opts.name_width_cap))
    print_user_legend()


def parse_args(argv: list[str]) -> Options:
    if not argv:
        print_quick_start()
        raise SystemExit(0)
    if argv[0] in ("-h", "--help"):
        print(USAGE)
        raise SystemExit(0)

    args = list(argv)
    target_type = args.pop(0)
    identifier = ""
    initial_query = ""

    if target_type == "search":
        if args and args[0] in ("group", "groups"):
            target_type = "search-groups"
            args.pop(0)
        elif args and args[0] in ("user", "users"):
            target_type = "search-users"
            args.pop(0)
        if args and not args[0].startswith("--"):
            initial_query = args.pop(0)
    elif target_type == "users":
        target_type = "search-users"
        if args and not args[0].startswith("--"):
            initial_query = args.pop(0)
    elif target_type == "groups":
        target_type = "search-groups"
        if args and not args[0].startswith("--"):
            initial_query = args.pop(0)
    elif target_type in ("dept", "department", "departments"):
        target_type = "dept"
        if args and not args[0].startswith("--"):
            initial_query = args.pop(0)
    elif target_type in ("search-users", "user-search", "users-search"):
        if args and not args[0].startswith("--"):
            initial_query = args.pop(0)
    elif target_type in ("search-groups", "group-search", "groups-search"):
        if args and not args[0].startswith("--"):
            initial_query = args.pop(0)
    elif target_type in ("user", "group"):
        if not args:
            die(f"Missing {target_type} identifier. Try: entra {target_type} <upn-or-id>. Run 'entra --help' for details.")
        identifier = args.pop(0)
    elif target_type in ("reports", "report", "org", "org-reports"):
        target_type = "reports"
        if args and not args[0].startswith("--"):
            value = args.pop(0)
            if is_guid(value) or "@" in value:
                identifier = value
            else:
                initial_query = value
    else:
        die("First argument must be 'user', 'group', 'reports', 'users', 'groups', 'dept', 'search', or 'search-groups'")

    opts = Options(target_type=target_type, identifier=identifier, initial_query=initial_query)
    while args:
        arg = args.pop(0)
        if arg == "--direct":
            opts.mode = "direct"
            opts.mode_explicit = True
        elif arg == "--transitive":
            opts.mode = "transitive"
            opts.mode_explicit = True
        elif arg == "--tsv":
            opts.tsv_output = True
        elif arg in ("--fzf", "--interactive"):
            opts.fzf_output = True
        elif arg == "--full":
            opts.full_output = True
        elif arg == "--refresh-cache":
            opts.refresh_cache = True
        elif arg == "--no-cache":
            opts.use_cache = False
        elif arg == "--color":
            if not args:
                die("--color requires one of: auto, always, never")
            opts.color_mode = args.pop(0)
        elif arg in ("--color=auto", "--color=always", "--color=never"):
            opts.color_mode = arg.split("=", 1)[1]
        elif arg == "--no-color":
            opts.color_mode = "never"
        elif arg == "--out":
            die("--out was removed. Use --tsv; the script generates the filename automatically.")
        elif arg in ("-h", "--help"):
            print(USAGE)
            raise SystemExit(0)
        else:
            die(f"Unknown argument: {arg}")
    return opts


def validate_options(opts: Options) -> None:
    search_targets = {"search", "search-users", "user-search", "users-search", "search-groups", "group-search", "groups-search", "dept"}

    if opts.target_type in search_targets and opts.tsv_output:
        die("--tsv is not supported with search commands; select an object first, then export with user or group mode if needed.")

    if opts.target_type == "dept":
        if opts.mode_explicit:
            die("--direct and --transitive are not supported with dept")
        if opts.fzf_output:
            die("--fzf and --interactive are not supported with dept; dept already opens a picker")

    is_reports = opts.target_type == "reports"
    if opts.target_type not in search_targets and not is_reports and (opts.refresh_cache or not opts.use_cache):
        die("--refresh-cache and --no-cache are only valid with search commands or reports")

    if opts.tsv_output and opts.fzf_output:
        die("--tsv and --fzf cannot be used together")

    if opts.target_type == "reports" and opts.identifier and opts.fzf_output:
        die("--fzf is not supported with direct reports lookup. Run reports without a user to use the picker.")


def run(opts: Options) -> None:
    global COLORS
    validate_options(opts)
    need_command("az")
    if (
        opts.fzf_output
        or opts.target_type in {"search", "search-users", "user-search", "users-search", "search-groups", "group-search", "groups-search", "dept"}
        or (opts.target_type == "reports" and not opts.identifier)
    ):
        need_command("fzf")

    COLORS = setup_color(opts.color_mode)
    state = State()

    if opts.target_type == "user":
        resolve_user(opts.identifier, state)
        relationship = "transitiveMemberOf" if opts.mode == "transitive" else "memberOf"
        out = ""
        if opts.tsv_output:
            slug = slugify(state.user_upn)
            out = f"{slug or 'user'}.{opts.mode}.groups.tsv"
        write_group_rows_for_user(relationship, out, opts.tsv_output, opts.mode, opts.fzf_output, state, opts)
    elif opts.target_type == "group":
        resolve_group(opts.identifier, state)
        relationship = "transitiveMembers" if opts.mode == "transitive" else "members"
        out = ""
        if opts.tsv_output:
            slug = slugify(state.group_display_name)
            out = f"{slug or 'group'}_{state.group_id[:8]}.{opts.mode}.users.tsv"
        write_user_rows_for_group(relationship, out, opts.tsv_output, opts.mode, opts.fzf_output, state, opts)
    elif opts.target_type == "reports":
        if opts.identifier:
            resolve_user(opts.identifier, state)
            out = ""
            if opts.tsv_output:
                slug = slugify(state.user_upn)
                out = f"{slug or 'user'}.{opts.mode}.reports.tsv"
            write_report_rows_for_user(out, opts.tsv_output, opts.mode, state, opts)
        else:
            search_reports(opts.mode, opts.initial_query, opts.use_cache, opts.refresh_cache, opts.tsv_output, state, opts)
    elif opts.target_type in ("search", "search-users", "user-search", "users-search"):
        search_users(opts.mode, opts.initial_query, opts.use_cache, opts.refresh_cache, state, opts)
    elif opts.target_type in ("search-groups", "group-search", "groups-search"):
        search_groups(opts.mode, opts.initial_query, opts.use_cache, opts.refresh_cache, state, opts)
    elif opts.target_type == "dept":
        search_departments(opts.initial_query, opts.use_cache, opts.refresh_cache, opts)
    else:
        die("First argument must be 'user', 'group', 'reports', 'users', 'groups', 'dept', 'search', or 'search-groups'")


def main(argv: list[str]) -> int:
    try:
        opts = parse_args(argv)
        run(opts)
        return 0
    except BrokenPipeError:
        return 0
    except AppError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
