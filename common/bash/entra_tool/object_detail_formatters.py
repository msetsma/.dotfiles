from typing import Any

from entra_tool.detail_formatters import print_kv, print_kv_continuation
from entra_tool.terminal import json_array, json_scalar
from entra_tool.terminal_colors import COLORS


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
            print_kv(
                "Proxy X500",
                f"{len(x500_values)} legacy Exchange address(es) hidden; pass --full to show",
            )

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
