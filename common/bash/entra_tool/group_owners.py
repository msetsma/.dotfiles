from entra_tool.detail_formatters import (
    print_kv,
    print_kv_continuation,
)
from entra_tool.errors import GraphError
from entra_tool.graph import graph_get, uri_encode
from entra_tool.terminal import clean


def print_group_owners(group_id: str, full_output: bool) -> None:
    encoded = uri_encode(group_id)
    try:
        obj = graph_get(
            f"https://graph.microsoft.com/v1.0/groups/{encoded}/owners?$select=id,displayName,userPrincipalName,mail&$top=20"
        )
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
        detail = clean(
            owner.get("userPrincipalName") or owner.get("mail") or owner.get("id")
        )
        if index == 0:
            print_kv("Owners", f"{name} <{detail}>")
        else:
            print_kv_continuation(f"{name} <{detail}>")
    if limit < len(owners):
        print_kv_continuation(
            f"{len(owners) - limit} more owner(s); pass --full to show first 20"
        )
