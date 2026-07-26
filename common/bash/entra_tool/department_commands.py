from typing import Any

from entra_tool.department_rows import (
    build_department_rows,
    top_values,
    users_for_department,
)
from entra_tool.department_table_formatters import format_department_user_table
from entra_tool.detail_formatters import print_kv, print_user_legend
from entra_tool.directory import load_user_search_rows
from entra_tool.errors import die
from entra_tool.managers import add_manager_details_to_user_rows
from entra_tool.models import Options
from entra_tool.picker import run_fzf, selected_hidden_value
from entra_tool.picker_formatters import format_picker_rows
from entra_tool.terminal import clean, sorted_rows, yn
from entra_tool.terminal_colors import COLORS


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


def search_departments(
    initial_query: str, use_cache: bool, refresh_cache: bool, opts: Options
) -> None:
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
    selected = run_fzf(
        format_picker_rows("department", department_rows),
        "Search departments > ",
        header,
        initial_query,
    )
    if selected is None:
        return
    parts = selected.split("\t")
    selected_key = selected_hidden_value(parts)
    if selected_key is None:
        return
    department_name = parts[2] if len(parts) > 2 else ""

    department_users = users_for_department(rows, selected_key)
    department_users = add_manager_details_to_user_rows(department_users)
    print()
    print_department_summary(department_name, department_users)
    print()
    print(
        format_department_user_table(
            sorted_rows(department_users), opts.full_output, opts.name_width_cap
        )
    )
    print_user_legend()
