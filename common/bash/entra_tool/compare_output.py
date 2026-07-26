from typing import Any, Callable

from entra_tool.compare import compare_subject_label
from entra_tool.detail_formatters import (
    print_group_legend,
    print_kv,
    print_mode,
    print_user_legend,
)
from entra_tool.group_table_formatters import format_group_table
from entra_tool.models import CompareSubject, Options
from entra_tool.terminal import clean
from entra_tool.terminal_colors import COLORS, styled
from entra_tool.user_table_formatters import format_user_table


TableFormatter = Callable[[list[list[Any]], bool, int], str]


def print_compare_section(
    title: str, rows: list[list[Any]], color: str, formatter: TableFormatter, opts: Options
) -> None:
    print(f"{COLORS.bold}{color}{title} ({len(rows)}){COLORS.reset}")
    if not rows:
        print(f"{COLORS.dim}(none){COLORS.reset}")
        return
    print(formatter(rows, opts.full_output, opts.name_width_cap))


def print_compare_header(
    title: str,
    left: CompareSubject,
    right: CompareSubject,
    mode: str,
    shared: int,
    left_only: int,
    right_only: int,
) -> None:
    print(f"{COLORS.bold}{COLORS.cyan}{title}{COLORS.reset}")
    print_kv("First", compare_subject_label(left))
    print_kv("Second", compare_subject_label(right))
    print_mode(mode)
    print_kv("Shared", styled(str(shared), COLORS.green))
    print_kv("Only first", styled(str(left_only), COLORS.yellow))
    print_kv("Only second", styled(str(right_only), COLORS.magenta))


def print_user_group_comparison(
    left: CompareSubject,
    right: CompareSubject,
    mode: str,
    shared_rows: list[list[Any]],
    left_only_rows: list[list[Any]],
    right_only_rows: list[list[Any]],
    opts: Options,
) -> None:
    print_compare_header(
        "User group membership comparison",
        left,
        right,
        mode,
        len(shared_rows),
        len(left_only_rows),
        len(right_only_rows),
    )
    print()
    print_compare_section(
        "Shared groups", shared_rows, COLORS.green, format_group_table, opts
    )
    print()
    print_compare_section(
        f"Only {clean(left.name)}",
        left_only_rows,
        COLORS.yellow,
        format_group_table,
        opts,
    )
    print()
    print_compare_section(
        f"Only {clean(right.name)}",
        right_only_rows,
        COLORS.magenta,
        format_group_table,
        opts,
    )
    print_group_legend()


def print_group_user_comparison(
    left: CompareSubject,
    right: CompareSubject,
    mode: str,
    shared_rows: list[list[Any]],
    left_only_rows: list[list[Any]],
    right_only_rows: list[list[Any]],
    opts: Options,
) -> None:
    print_compare_header(
        "Group user membership comparison",
        left,
        right,
        mode,
        len(shared_rows),
        len(left_only_rows),
        len(right_only_rows),
    )
    print()
    print_compare_section(
        "Shared users", shared_rows, COLORS.green, format_user_table, opts
    )
    print()
    print_compare_section(
        f"Only {clean(left.name)}",
        left_only_rows,
        COLORS.yellow,
        format_user_table,
        opts,
    )
    print()
    print_compare_section(
        f"Only {clean(right.name)}",
        right_only_rows,
        COLORS.magenta,
        format_user_table,
        opts,
    )
    print_user_legend()
