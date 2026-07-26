from entra_tool.cli_targets import GROUP_SEARCH_TARGETS, USER_SEARCH_TARGETS
from entra_tool.compare_commands import compare_groups, compare_users
from entra_tool.compare_selection import pick_compare_kind
from entra_tool.department_commands import search_departments
from entra_tool.membership_commands import (
    write_group_rows_for_user,
    write_user_rows_for_group,
)
from entra_tool.models import Options, State
from entra_tool.output_paths import (
    group_users_tsv_path,
    reports_tsv_path,
    user_groups_tsv_path,
)
from entra_tool.report_commands import search_reports, write_report_rows_for_user
from entra_tool.resolvers import resolve_group, resolve_user
from entra_tool.search_commands import search_groups, search_users


def run_user_command(opts: Options, state: State) -> None:
    resolve_user(opts.identifier, state)
    out = user_groups_tsv_path(state, opts.mode) if opts.tsv_output else ""
    write_group_rows_for_user(
        out, opts.tsv_output, opts.mode, opts.fzf_output, state, opts
    )


def run_group_command(opts: Options, state: State) -> None:
    resolve_group(opts.identifier, state)
    out = group_users_tsv_path(state, opts.mode) if opts.tsv_output else ""
    write_user_rows_for_group(
        out, opts.tsv_output, opts.mode, opts.fzf_output, state, opts
    )


def run_report_command(opts: Options, state: State) -> None:
    if opts.identifier:
        resolve_user(opts.identifier, state)
        out = reports_tsv_path(state, opts.mode) if opts.tsv_output else ""
        write_report_rows_for_user(out, opts.tsv_output, opts.mode, state, opts)
        return
    search_reports(
        opts.mode,
        opts.initial_query,
        opts.use_cache,
        opts.refresh_cache,
        opts.tsv_output,
        state,
        opts,
    )


def run_compare_command(opts: Options) -> None:
    if opts.target_type == "compare":
        kind = pick_compare_kind()
        if kind == "users":
            compare_users(opts)
        elif kind == "groups":
            compare_groups(opts)
        return
    if opts.target_type == "compare-users":
        compare_users(opts)
        return
    compare_groups(opts)


def run_search_command(opts: Options, state: State) -> None:
    if opts.target_type in USER_SEARCH_TARGETS:
        search_users(
            opts.mode,
            opts.initial_query,
            opts.use_cache,
            opts.refresh_cache,
            state,
            opts,
        )
        return
    if opts.target_type in GROUP_SEARCH_TARGETS:
        search_groups(
            opts.mode,
            opts.initial_query,
            opts.use_cache,
            opts.refresh_cache,
            state,
            opts,
        )
        return
    search_departments(opts.initial_query, opts.use_cache, opts.refresh_cache, opts)
