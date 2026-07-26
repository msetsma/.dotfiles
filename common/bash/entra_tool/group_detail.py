from typing import Any

from entra_tool.errors import GraphError, die
from entra_tool.graph import graph_get, uri_encode
from entra_tool.graph_fields import select_fields


GROUP_DETAIL_FIELDS = [
    "id",
    "displayName",
    "description",
    "mail",
    "mailNickname",
    "mailEnabled",
    "securityEnabled",
    "groupTypes",
    "visibility",
    "classification",
    "createdDateTime",
    "renewedDateTime",
    "expirationDateTime",
    "membershipRule",
    "membershipRuleProcessingState",
    "onPremisesSyncEnabled",
    "onPremisesLastSyncDateTime",
    "onPremisesSecurityIdentifier",
    "proxyAddresses",
    "resourceProvisioningOptions",
    "resourceBehaviorOptions",
]
GROUP_ROLE_ASSIGNMENT_FIELD = "isAssignableToRole"


def fetch_group_detail(selected_group_id: str) -> dict[str, Any]:
    encoded = uri_encode(selected_group_id)
    safe_fields = select_fields(GROUP_DETAIL_FIELDS)
    full_fields = select_fields(GROUP_DETAIL_FIELDS + [GROUP_ROLE_ASSIGNMENT_FIELD])
    full_url = f"https://graph.microsoft.com/v1.0/groups/{encoded}?$select={full_fields}"
    safe_url = f"https://graph.microsoft.com/v1.0/groups/{encoded}?$select={safe_fields}"
    try:
        return graph_get(full_url)
    except GraphError:
        try:
            return graph_get(safe_url)
        except GraphError:
            die(
                f"Group detail lookup failed for selected group id: {selected_group_id}"
            )
