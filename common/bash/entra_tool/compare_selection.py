from typing import Callable

from entra_tool.compare import rows_excluding_object_id
from entra_tool.directory import load_group_search_rows, load_user_search_rows
from entra_tool.errors import die
from entra_tool.models import CompareSubject, Options, State
from entra_tool.picker import run_fzf, selected_hidden_value
from entra_tool.picker_formatters import format_picker_rows
from entra_tool.picker_table import picker_emit
from entra_tool.resolvers import resolve_group, resolve_user
from entra_tool.terminal import cell
from entra_tool.terminal_colors import COLORS


def format_compare_kind_picker() -> str:
    return picker_emit(
        ["COMPARE"],
        [18],
        [
            ([cell("Users", 18)], ["users", "Users", ""]),
            ([cell("Groups", 18)], ["groups", "Groups", ""]),
        ],
    )


def pick_compare_kind() -> str | None:
    header = (
        f"{COLORS.bold}Compare:{COLORS.reset} choose whether to compare users or groups\n"
        f"{COLORS.dim}Users compare group membership; groups compare user membership.{COLORS.reset}"
    )
    selected = run_fzf(format_compare_kind_picker(), "Compare > ", header)
    if selected is None:
        return None
    parts = selected.split("\t")
    kind = selected_hidden_value(parts)
    if kind not in {"users", "groups"}:
        return None
    return kind


def compare_user_from_identifier(identifier: str) -> CompareSubject:
    state = State()
    resolve_user(identifier, state)
    return CompareSubject(
        kind="user",
        object_id=state.user_id,
        name=state.user_display_name,
        detail=state.user_upn,
    )


def compare_group_from_identifier(identifier: str) -> CompareSubject:
    state = State()
    resolve_group(identifier, state)
    return CompareSubject(
        kind="group",
        object_id=state.group_id,
        name=state.group_display_name,
        detail=state.group_mail,
    )


def compare_user_from_picker_parts(parts: list[str]) -> CompareSubject | None:
    return compare_subject_from_picker_parts("user", parts)


def compare_group_from_picker_parts(parts: list[str]) -> CompareSubject | None:
    return compare_subject_from_picker_parts("group", parts)


def compare_subject_from_picker_parts(
    kind: str, parts: list[str]
) -> CompareSubject | None:
    object_id = selected_hidden_value(parts)
    if object_id is None:
        return None
    return CompareSubject(
        kind=kind,
        object_id=object_id,
        name=parts[2] if len(parts) > 2 else "",
        detail=parts[3] if len(parts) > 3 else "",
    )


def pick_compare_user_subject(
    label: str, opts: Options, exclude_id: str = ""
) -> CompareSubject | None:
    rows, loaded_from_cache = load_user_search_rows(opts.use_cache, opts.refresh_cache)
    rows = rows_excluding_object_id(rows, 3, exclude_id)
    if not rows:
        die("No users returned from Microsoft Graph.")
    cache_state = "hit" if loaded_from_cache else "fresh"
    header = (
        f"{COLORS.bold}Select {label} user:{COLORS.reset} type to filter, Enter selects, Esc cancels\n"
        f"{COLORS.dim}User legend:{COLORS.reset} ENABLED=account enabled, TYPE=Entra user type, CACHE={cache_state}"
    )
    selected = run_fzf(
        format_picker_rows("search_user", rows), f"{label.title()} user > ", header
    )
    if selected is None:
        return None
    return compare_user_from_picker_parts(selected.split("\t"))


def pick_compare_group_subject(
    label: str, opts: Options, exclude_id: str = ""
) -> CompareSubject | None:
    rows, loaded_from_cache = load_group_search_rows(opts.use_cache, opts.refresh_cache)
    rows = rows_excluding_object_id(rows, 2, exclude_id)
    if not rows:
        die("No groups returned from Microsoft Graph.")
    cache_state = "hit" if loaded_from_cache else "fresh"
    header = (
        f"{COLORS.bold}Select {label} group:{COLORS.reset} type to filter, Enter selects, Esc cancels\n"
        f"{COLORS.dim}Group legend:{COLORS.reset} MAIL_EN=mail enabled, SEC_EN=security enabled, TYPE=group type, CREATED=created date, CACHE={cache_state}"
    )
    selected = run_fzf(
        format_picker_rows("group", rows), f"{label.title()} group > ", header
    )
    if selected is None:
        return None
    return compare_group_from_picker_parts(selected.split("\t"))


def select_compare_user_subjects(
    opts: Options,
) -> tuple[CompareSubject, CompareSubject] | None:
    return select_compare_subjects(
        opts,
        compare_user_from_identifier,
        pick_compare_user_subject,
        "users",
    )


def select_compare_group_subjects(
    opts: Options,
) -> tuple[CompareSubject, CompareSubject] | None:
    return select_compare_subjects(
        opts,
        compare_group_from_identifier,
        pick_compare_group_subject,
        "groups",
    )


def select_compare_subjects(
    opts: Options,
    from_identifier: Callable[[str], CompareSubject],
    pick_subject: Callable[[str, Options, str], CompareSubject | None],
    noun: str,
) -> tuple[CompareSubject, CompareSubject] | None:
    if opts.left_identifier:
        left = from_identifier(opts.left_identifier)
    else:
        left = pick_subject("first", opts, "")
        if left is None:
            return None

    if opts.right_identifier:
        right = from_identifier(opts.right_identifier)
    else:
        right = pick_subject("second", opts, left.object_id)
        if right is None:
            return None

    if left.object_id == right.object_id:
        die(f"Select two different {noun} to compare.")
    return left, right
