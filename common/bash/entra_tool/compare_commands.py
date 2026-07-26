from typing import Any

from entra_tool.compare import (
    compare_rows_by_object_id,
    dedupe_rows_by_object_id,
)
from entra_tool.compare_output import (
    print_group_user_comparison,
    print_user_group_comparison,
)
from entra_tool.directory import (
    fetch_group_rows_for_user_id,
    fetch_user_rows_for_group_id,
)
from entra_tool.compare_selection import (
    select_compare_group_subjects,
    select_compare_user_subjects,
)
from entra_tool.managers import add_manager_details_to_user_rows
from entra_tool.models import Options


def enrich_user_rows_once(rows: list[list[Any]]) -> list[list[Any]]:
    return add_manager_details_to_user_rows(dedupe_rows_by_object_id(rows, 3))


def compare_users(opts: Options) -> None:
    selected = select_compare_user_subjects(opts)
    if selected is None:
        return
    left, right = selected

    left_rows = fetch_group_rows_for_user_id(left.object_id, opts.mode)
    right_rows = fetch_group_rows_for_user_id(right.object_id, opts.mode)
    shared_rows, left_only_rows, right_only_rows = compare_rows_by_object_id(
        left_rows, right_rows, 2
    )

    print_user_group_comparison(
        left,
        right,
        opts.mode,
        shared_rows,
        left_only_rows,
        right_only_rows,
        opts,
    )


def compare_groups(opts: Options) -> None:
    selected = select_compare_group_subjects(opts)
    if selected is None:
        return
    left, right = selected

    left_rows = fetch_user_rows_for_group_id(left.object_id, opts.mode)
    right_rows = fetch_user_rows_for_group_id(right.object_id, opts.mode)
    shared_rows, left_only_rows, right_only_rows = [
        enrich_user_rows_once(rows)
        for rows in compare_rows_by_object_id(left_rows, right_rows, 3)
    ]

    print_group_user_comparison(
        left,
        right,
        opts.mode,
        shared_rows,
        left_only_rows,
        right_only_rows,
        opts,
    )
