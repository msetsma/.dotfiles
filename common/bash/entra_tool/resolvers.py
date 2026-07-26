import csv
import sys

from entra_tool.errors import AppError, GraphError
from entra_tool.graph import graph_get, odata_string_literal, uri_encode
from entra_tool.graph_fields import GROUP_SEARCH_FIELDS, USER_RESOLVE_FIELDS, select_fields
from entra_tool.models import State
from entra_tool.rows import group_row
from entra_tool.terminal import clean
from entra_tool.text import is_guid, is_short_hex_id_prefix, looks_like_bad_guid
from entra_tool.tsv import tsv_value

def resolve_user(identifier: str, state: State) -> None:
    encoded = uri_encode(identifier)
    try:
        obj = graph_get(
            f"https://graph.microsoft.com/v1.0/users/{encoded}?$select={select_fields(USER_RESOLVE_FIELDS)}"
        )
    except GraphError:
        raise AppError(
            f"User not found: {identifier}. Use the user's full UPN/email address or Entra object id."
        )

    state.user_id = clean(obj.get("id"))
    state.user_display_name = obj.get("displayName") or ""
    state.user_upn = obj.get("userPrincipalName") or ""
    if state.user_id == "-":
        raise AppError(f"User not found: {identifier}")


def resolve_group(identifier: str, state: State) -> None:
    if is_guid(identifier):
        encoded = uri_encode(identifier)
        try:
            obj = graph_get(
                f"https://graph.microsoft.com/v1.0/groups/{encoded}?$select={select_fields(GROUP_SEARCH_FIELDS)}"
            )
        except GraphError:
            raise AppError(
                f"Group not found: {identifier}. Use a full group object id or exact display name."
            )
    elif looks_like_bad_guid(identifier):
        raise AppError(f"This looks like a group id with extra characters: {identifier}")
    elif is_short_hex_id_prefix(identifier):
        raise AppError("Short group id prefixes are not supported. Use the full group id.")
    else:
        filter_value = uri_encode(f"displayName eq {odata_string_literal(identifier)}")
        try:
            result = graph_get(
                f"https://graph.microsoft.com/v1.0/groups?$filter={filter_value}&$select={select_fields(GROUP_SEARCH_FIELDS)}&$top=50"
            )
        except GraphError:
            raise AppError(f"Group lookup failed for: {identifier}")
        matches = result.get("value") or []
        if not matches:
            raise AppError(f"No group found with displayName exactly equal to: {identifier}")
        if len(matches) > 1:
            print(
                f'Multiple groups found for displayName "{identifier}". Re-run with the group id:',
                file=sys.stderr,
            )
            writer = csv.writer(sys.stderr, delimiter="\t", lineterminator="\n")
            writer.writerow(
                [
                    "displayName",
                    "mail",
                    "id",
                    "mailEnabled",
                    "securityEnabled",
                    "groupTypes",
                    "createdDateTime",
                ]
            )
            for group in matches:
                writer.writerow([tsv_value(value) for value in group_row(group)])
            raise SystemExit(2)
        obj = matches[0]

    state.group_id = clean(obj.get("id"))
    state.group_display_name = obj.get("displayName") or ""
    state.group_mail = obj.get("mail") or ""
    if state.group_id == "-":
        raise AppError(f"Group not found: {identifier}")
