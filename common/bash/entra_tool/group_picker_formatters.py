from typing import Any

from entra_tool.picker_table import picker_emit
from entra_tool.terminal import (
    bool_color,
    cell,
    clean,
    date_value,
    fit,
    sorted_rows,
    text_color,
    type_color,
    yn,
)
from entra_tool.terminal_colors import COLORS


def format_group_picker_rows(rows: list[list[Any]]) -> str:
    headers = ["GROUP", "MAIL", "ID", "MAIL_EN", "SEC_EN", "TYPE", "CREATED"]
    widths = [56, 72, 36, 7, 6, 18, 10]
    picker_rows = []
    for row in sorted_rows(rows):
        padded = list(row) + [""] * (7 - len(row))
        name = fit(padded[0], 56)
        mail = fit(padded[1], 72)
        object_id = clean(padded[2])
        mail_enabled = yn(padded[3])
        security_enabled = yn(padded[4])
        group_type = fit(padded[5], 18)
        created = date_value(padded[6])
        picker_rows.append(
            (
                [
                    cell(name, 56),
                    cell(mail, 72, text_color(mail, COLORS.blue)),
                    cell(object_id, 36, COLORS.gray),
                    cell(mail_enabled, 7, bool_color(mail_enabled)),
                    cell(security_enabled, 6, bool_color(security_enabled)),
                    cell(group_type, 18, type_color(group_type)),
                    cell(created, 10, COLORS.gray),
                ],
                [object_id, clean(padded[0]), clean(padded[1])],
            )
        )
    return picker_emit(headers, widths, picker_rows)
