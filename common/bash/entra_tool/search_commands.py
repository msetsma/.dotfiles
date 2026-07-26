from entra_tool.directory import (
    fetch_group_rows_for_user_id,
    fetch_user_rows_for_group_id,
    fetch_user_detail,
    load_group_search_rows,
    load_user_search_rows,
)
from entra_tool.errors import GraphError, die
from entra_tool.object_detail_formatters import print_group_details, print_user_details
from entra_tool.terminal_colors import COLORS
from entra_tool.group_detail import fetch_group_detail
from entra_tool.group_owners import print_group_owners
from entra_tool.managers import add_manager_details_to_user_rows, fetch_user_manager_details
from entra_tool.membership_output import (
    print_group_rows_for_user,
    print_user_rows_for_group,
)
from entra_tool.models import Options, State
from entra_tool.picker import run_fzf, selected_hidden_value
from entra_tool.picker_formatters import format_picker_rows


def show_selected_user_report(
    selected_user_id: str, mode: str, state: State, opts: Options
) -> None:
    try:
        obj = fetch_user_detail(selected_user_id)
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
    rows = fetch_group_rows_for_user_id(state.user_id, mode)
    print_group_rows_for_user(rows, mode, state, opts)


def search_users(
    mode: str,
    initial_query: str,
    use_cache: bool,
    refresh_cache: bool,
    state: State,
    opts: Options,
) -> None:
    rows, loaded_from_cache = load_user_search_rows(use_cache, refresh_cache)
    if not rows:
        die("No users returned from Microsoft Graph.")
    cache_state = "hit" if loaded_from_cache else "fresh"
    header = (
        f"{COLORS.bold}Search users:{COLORS.reset} type to filter, Up/Down moves, Enter prints user details and groups, Esc cancels\n"
        f"{COLORS.dim}User legend:{COLORS.reset} ENABLED=account enabled, TYPE=Entra user type, CACHE={cache_state}"
    )
    selected = run_fzf(
        format_picker_rows("search_user", rows),
        "Search users > ",
        header,
        initial_query,
    )
    if selected is None:
        return
    parts = selected.split("\t")
    user_id = selected_hidden_value(parts)
    if user_id is None:
        return
    show_selected_user_report(user_id, mode, state, opts)


def show_selected_group_report(
    selected_group_id: str, mode: str, state: State, opts: Options
) -> None:
    obj = fetch_group_detail(selected_group_id)
    state.group_id = obj.get("id") or ""
    state.group_display_name = obj.get("displayName") or ""
    state.group_mail = obj.get("mail") or ""
    print()
    print_group_details(obj, opts.full_output)
    print_group_owners(state.group_id, opts.full_output)
    print()
    rows = fetch_user_rows_for_group_id(state.group_id, mode)
    print_user_rows_for_group(
        add_manager_details_to_user_rows(rows), mode, state, opts
    )


def search_groups(
    mode: str,
    initial_query: str,
    use_cache: bool,
    refresh_cache: bool,
    state: State,
    opts: Options,
) -> None:
    rows, loaded_from_cache = load_group_search_rows(use_cache, refresh_cache)
    if not rows:
        die("No groups returned from Microsoft Graph.")
    cache_state = "hit" if loaded_from_cache else "fresh"
    header = (
        f"{COLORS.bold}Search groups:{COLORS.reset} type to filter, Up/Down moves, Enter prints group details and users, Esc cancels\n"
        f"{COLORS.dim}Group legend:{COLORS.reset} MAIL_EN=mail enabled, SEC_EN=security enabled, TYPE=group type, CREATED=created date, CACHE={cache_state}"
    )
    selected = run_fzf(
        format_picker_rows("group", rows), "Search groups > ", header, initial_query
    )
    if selected is None:
        return
    parts = selected.split("\t")
    group_id = selected_hidden_value(parts)
    if group_id is None:
        return
    show_selected_group_report(group_id, mode, state, opts)
