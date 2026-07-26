from typing import Any, Callable

from entra_tool.department_picker_formatters import format_department_picker_rows
from entra_tool.errors import AppError
from entra_tool.group_picker_formatters import format_group_picker_rows
from entra_tool.user_picker_formatters import (
    format_search_user_picker_rows,
    format_user_picker_rows,
)


PICKER_FORMATTERS: dict[str, Callable[[list[list[Any]]], str]] = {
    "department": format_department_picker_rows,
    "group": format_group_picker_rows,
    "search_user": format_search_user_picker_rows,
    "user": format_user_picker_rows,
}


def format_picker_rows(kind: str, rows: list[list[Any]]) -> str:
    formatter = PICKER_FORMATTERS.get(kind)
    if formatter is None:
        raise AppError(f"unknown picker kind: {kind}")
    return formatter(rows)
