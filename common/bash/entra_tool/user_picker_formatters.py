from typing import Any

from entra_tool.picker_table import picker_emit
from entra_tool.terminal import bool_color, cell, clean, fit, sorted_rows, text_color, yn
from entra_tool.terminal_colors import COLORS


def format_user_picker_rows(rows: list[list[Any]]) -> str:
    headers = ["USER", "UPN", "MAIL", "ID", "ENABLED"]
    widths = [42, 40, 40, 36, 7]
    picker_rows = []
    for row in sorted_rows(rows):
        padded = list(row) + [""] * (5 - len(row))
        name = fit(padded[0], 42)
        upn = fit(padded[1], 40)
        mail = fit(padded[2], 40)
        object_id = clean(padded[3])
        enabled = yn(padded[4])
        picker_rows.append(
            (
                [
                    cell(name, 42),
                    cell(upn, 40, text_color(upn, COLORS.blue)),
                    cell(mail, 40, text_color(mail, COLORS.blue)),
                    cell(object_id, 36, COLORS.gray),
                    cell(enabled, 7, bool_color(enabled)),
                ],
                [object_id, clean(padded[0]), clean(padded[1])],
            )
        )
    return picker_emit(headers, widths, picker_rows)


def format_search_user_picker_rows(rows: list[list[Any]]) -> str:
    headers = ["USER", "UPN", "MAIL", "TITLE", "DEPT", "TYPE", "ENABLED"]
    widths = [34, 42, 42, 28, 24, 10, 7]
    picker_rows = []
    for row in sorted_rows(rows):
        padded = list(row) + [""] * (10 - len(row))
        name = fit(padded[0], 34)
        upn = fit(padded[1], 42)
        mail = fit(padded[2], 42)
        object_id = clean(padded[3])
        enabled = yn(padded[4])
        user_type = fit(padded[5], 10)
        title = fit(padded[6], 28)
        dept = fit(padded[7], 24)
        picker_rows.append(
            (
                [
                    cell(name, 34),
                    cell(upn, 42, text_color(upn, COLORS.blue)),
                    cell(mail, 42, text_color(mail, COLORS.blue)),
                    cell(title, 28),
                    cell(dept, 24),
                    cell(user_type, 10, COLORS.gray),
                    cell(enabled, 7, bool_color(enabled)),
                ],
                [object_id, clean(padded[0]), clean(padded[1])],
            )
        )
    return picker_emit(headers, widths, picker_rows)
