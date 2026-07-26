from entra_tool.directory import (
    fetch_report_user_json,
    load_user_search_rows,
)
from entra_tool.errors import GraphError, die
from entra_tool.detail_formatters import (
    print_kv,
    print_report_mode,
    print_reports_legend,
)
from entra_tool.report_table_formatters import format_reports_table
from entra_tool.terminal_colors import COLORS
from entra_tool.models import Options, State
from entra_tool.output_paths import reports_tsv_path
from entra_tool.picker import run_fzf, selected_hidden_value
from entra_tool.picker_formatters import format_picker_rows
from entra_tool.report_rows import report_has_title, report_is_enabled, report_is_visible
from entra_tool.report_tree import collect_report_tree
from entra_tool.tsv_outputs import write_report_tsv


def write_report_rows_for_user(
    out: str, tsv_output: bool, mode: str, state: State, opts: Options
) -> None:
    try:
        root_json = fetch_report_user_json(state.user_id)
    except GraphError:
        die(f"User detail lookup failed for reports root: {state.user_id}")

    state.user_display_name = root_json.get("displayName") or ""
    state.user_upn = root_json.get("userPrincipalName") or ""

    rows, users = collect_report_tree(
        state.user_id, root_json, mode, opts.use_cache, opts.refresh_cache
    )
    hidden_disabled = sum(1 for user in users.values() if not report_is_enabled(user))
    hidden_missing_title = sum(
        1
        for user in users.values()
        if report_is_enabled(user) and not report_has_title(user)
    )

    if tsv_output and out:
        write_report_tsv(out, rows)
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


def search_reports(
    mode: str,
    initial_query: str,
    use_cache: bool,
    refresh_cache: bool,
    tsv_output: bool,
    state: State,
    opts: Options,
) -> None:
    rows, loaded_from_cache = load_user_search_rows(use_cache, refresh_cache)
    if not rows:
        die("No users returned from Microsoft Graph.")
    cache_state = "hit" if loaded_from_cache else "fresh"
    header = (
        f"{COLORS.bold}Search users for reports:{COLORS.reset} type to filter, Up/Down moves, Enter prints report hierarchy, Esc cancels\n"
        f"{COLORS.dim}User legend:{COLORS.reset} ENABLED=account enabled, TYPE=Entra user type, CACHE={cache_state}"
    )
    selected = run_fzf(
        format_picker_rows("search_user", rows),
        "Search reports root > ",
        header,
        initial_query,
    )
    if selected is None:
        return
    parts = selected.split("\t")
    user_id = selected_hidden_value(parts)
    if user_id is None:
        return
    state.user_id = user_id
    state.user_display_name = parts[2] if len(parts) > 2 else ""
    state.user_upn = parts[3] if len(parts) > 3 else ""
    out = reports_tsv_path(state, mode) if tsv_output else ""
    if not tsv_output:
        print()
    write_report_rows_for_user(out, tsv_output, mode, state, opts)
