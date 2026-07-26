from entra_tool.errors import die
from entra_tool.models import Options
from entra_tool.text import is_guid


SEARCH_TARGETS = {
    "search",
    "search-users",
    "user-search",
    "users-search",
    "search-groups",
    "group-search",
    "groups-search",
    "dept",
}
USER_SEARCH_TARGETS = {"search", "search-users", "user-search", "users-search"}
GROUP_SEARCH_TARGETS = {"search-groups", "group-search", "groups-search"}
CACHE_TARGETS = {"cache-status", "cache-refresh"}
COMPARE_TARGETS = {"compare", "compare-users", "compare-groups"}
FIRST_ARGUMENT_ERROR = (
    "First argument must be 'user', 'group', 'compare', 'compare-users', "
    "'compare-groups', 'reports', 'users', 'groups', 'dept', 'search', "
    "'search-groups', or 'cache'"
)


def read_compare_identifiers(args: list[str]) -> tuple[str, str]:
    left_identifier = ""
    right_identifier = ""
    if args and not args[0].startswith("--"):
        left_identifier = args.pop(0)
    if args and not args[0].startswith("--"):
        right_identifier = args.pop(0)
    if args and not args[0].startswith("--"):
        die(
            "compare accepts at most two identifiers. Quote group names that contain spaces."
        )
    return left_identifier, right_identifier


def read_initial_query(args: list[str]) -> str:
    if args and not args[0].startswith("--"):
        return args.pop(0)
    return ""


def parse_target(args: list[str]) -> Options:
    target_type = args.pop(0)
    identifier = ""
    initial_query = ""
    left_identifier = ""
    right_identifier = ""

    if target_type == "compare":
        if args and not args[0].startswith("--"):
            kind = args.pop(0)
            if kind in ("user", "users"):
                target_type = "compare-users"
                left_identifier, right_identifier = read_compare_identifiers(args)
            elif kind in ("group", "groups"):
                target_type = "compare-groups"
                left_identifier, right_identifier = read_compare_identifiers(args)
            else:
                die("compare requires users or groups. Try: entra compare users")
    elif target_type in (
        "compare-users",
        "compare-user",
        "users-compare",
        "user-compare",
    ):
        target_type = "compare-users"
        left_identifier, right_identifier = read_compare_identifiers(args)
    elif target_type in (
        "compare-groups",
        "compare-group",
        "groups-compare",
        "group-compare",
    ):
        target_type = "compare-groups"
        left_identifier, right_identifier = read_compare_identifiers(args)
    elif target_type == "search":
        if args and args[0] in ("group", "groups"):
            target_type = "search-groups"
            args.pop(0)
        elif args and args[0] in ("user", "users"):
            target_type = "search-users"
            args.pop(0)
        initial_query = read_initial_query(args)
    elif target_type == "users":
        target_type = "search-users"
        initial_query = read_initial_query(args)
    elif target_type == "groups":
        target_type = "search-groups"
        initial_query = read_initial_query(args)
    elif target_type in ("dept", "department", "departments"):
        target_type = "dept"
        initial_query = read_initial_query(args)
    elif target_type in ("search-users", "user-search", "users-search"):
        initial_query = read_initial_query(args)
    elif target_type in ("search-groups", "group-search", "groups-search"):
        initial_query = read_initial_query(args)
    elif target_type in ("user", "group"):
        if not args:
            die(
                f"Missing {target_type} identifier. Try: entra {target_type} <upn-or-id>. Run 'entra --help' for details."
            )
        identifier = args.pop(0)
    elif target_type in ("reports", "report", "org", "org-reports"):
        target_type = "reports"
        if args and not args[0].startswith("--"):
            value = args.pop(0)
            if is_guid(value) or "@" in value:
                identifier = value
            else:
                initial_query = value
    elif target_type == "cache":
        if not args or args[0].startswith("--"):
            die("cache requires a subcommand: status or refresh")
        subcommand = args.pop(0)
        if subcommand not in ("status", "refresh"):
            die("cache requires a subcommand: status or refresh")
        target_type = f"cache-{subcommand}"
    else:
        die(FIRST_ARGUMENT_ERROR)

    return Options(
        target_type=target_type,
        identifier=identifier,
        initial_query=initial_query,
        left_identifier=left_identifier,
        right_identifier=right_identifier,
    )
