from typing import Any

from entra_tool.detail_formatters import (
    print_group_legend,
    print_kv,
    print_mode,
    print_user_legend,
)
from entra_tool.group_table_formatters import format_group_table
from entra_tool.models import Options, State
from entra_tool.terminal import sorted_rows
from entra_tool.terminal_colors import COLORS
from entra_tool.user_table_formatters import format_user_table


def print_group_rows_for_user(
    rows: list[list[Any]], mode: str, state: State, opts: Options
) -> None:
    print(f"{COLORS.bold}{COLORS.cyan}User group membership{COLORS.reset}")
    print_kv("User", state.user_display_name)
    print_kv("UPN", state.user_upn)
    print_mode(mode)
    print_kv("Groups", len(rows))
    print()
    print(format_group_table(sorted_rows(rows), opts.full_output, opts.name_width_cap))
    print_group_legend()


def print_user_rows_for_group(
    rows: list[list[Any]], mode: str, state: State, opts: Options
) -> None:
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
