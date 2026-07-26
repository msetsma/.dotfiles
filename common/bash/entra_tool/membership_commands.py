from typing import Any

from entra_tool.directory import fetch_group_rows_for_user_id, fetch_user_rows_for_group_id
from entra_tool.errors import die
from entra_tool.terminal_colors import COLORS
from entra_tool.managers import add_manager_details_to_user_rows
from entra_tool.membership_output import (
    print_group_rows_for_user,
    print_user_rows_for_group,
)
from entra_tool.models import Options, State
from entra_tool.picker import run_fzf, selected_hidden_value
from entra_tool.picker_formatters import format_picker_rows
from entra_tool.tsv_outputs import write_group_membership_tsv, write_user_membership_tsv


def pick_group_then_show_users(
    rows: list[list[Any]], mode: str, state: State, opts: Options
) -> None:
    header = (
        f"{COLORS.bold}Search groups:{COLORS.reset} type to filter, Up/Down moves, Enter opens users for the highlighted group, Esc cancels\n"
        f"{COLORS.dim}Group legend:{COLORS.reset} MAIL_EN=mail enabled, SEC_EN=security enabled, TYPE=group type, CREATED=created date; Unified=Microsoft 365 group, DynamicMembership=rule-based membership"
    )
    selected = run_fzf(format_picker_rows("group", rows), "Search groups > ", header)
    if selected is None:
        return
    parts = selected.split("\t")
    group_id = selected_hidden_value(parts)
    if group_id is None:
        return
    state.group_id = group_id
    state.group_display_name = parts[2] if len(parts) > 2 else ""
    state.group_mail = parts[3] if len(parts) > 3 else ""
    print()
    write_user_rows_for_group("", False, mode, False, state, opts)


def pick_user_then_show_groups(
    rows: list[list[Any]], mode: str, state: State, opts: Options
) -> None:
    header = (
        f"{COLORS.bold}Search users:{COLORS.reset} type to filter, Up/Down moves, Enter opens groups for the highlighted user, Esc cancels\n"
        f"{COLORS.dim}User legend:{COLORS.reset} ENABLED=account enabled"
    )
    selected = run_fzf(format_picker_rows("user", rows), "Search users > ", header)
    if selected is None:
        return
    parts = selected.split("\t")
    user_id = selected_hidden_value(parts)
    if user_id is None:
        return
    state.user_id = user_id
    state.user_display_name = parts[2] if len(parts) > 2 else ""
    state.user_upn = parts[3] if len(parts) > 3 else ""
    print()
    write_group_rows_for_user("", False, mode, False, state, opts)


def write_group_rows_for_user(
    out: str,
    tsv_output: bool,
    mode: str,
    fzf_output: bool,
    state: State,
    opts: Options,
) -> None:
    rows = fetch_group_rows_for_user_id(state.user_id, mode)

    if tsv_output and out:
        write_group_membership_tsv(out, rows)
        return
    if tsv_output:
        die("Internal error: TSV output path was not set")
    if fzf_output:
        pick_group_then_show_users(rows, mode, state, opts)
        return

    print_group_rows_for_user(rows, mode, state, opts)


def write_user_rows_for_group(
    out: str,
    tsv_output: bool,
    mode: str,
    fzf_output: bool,
    state: State,
    opts: Options,
) -> None:
    rows = fetch_user_rows_for_group_id(state.group_id, mode)

    if fzf_output:
        pick_user_then_show_groups(rows, mode, state, opts)
        return

    rows = add_manager_details_to_user_rows(rows)

    if tsv_output and out:
        write_user_membership_tsv(out, rows)
        return
    if tsv_output:
        die("Internal error: TSV output path was not set")

    print_user_rows_for_group(rows, mode, state, opts)
