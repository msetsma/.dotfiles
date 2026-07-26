from typing import Any

from entra_tool.picker_table import picker_emit
from entra_tool.terminal import cell, clean, fit
from entra_tool.terminal_colors import COLORS


def format_department_picker_rows(rows: list[list[Any]]) -> str:
    headers = [
        "DEPARTMENT",
        "USERS",
        "ENABLED",
        "DISABLED",
        "GUESTS",
        "NO_TITLE",
        "COMPANIES",
        "OFFICES",
    ]
    widths = [56, 7, 7, 8, 6, 8, 9, 7]
    picker_rows = []
    for row in rows:
        padded = list(row) + [""] * (9 - len(row))
        department = fit(padded[0], 56)
        key = clean(padded[1])
        users = clean(padded[2])
        enabled = clean(padded[3])
        disabled = clean(padded[4])
        guests = clean(padded[5])
        missing_title = clean(padded[6])
        companies = clean(padded[7])
        offices = clean(padded[8])
        picker_rows.append(
            (
                [
                    cell(department, 56),
                    cell(users, 7, COLORS.gray),
                    cell(enabled, 7, COLORS.green),
                    cell(disabled, 8, COLORS.yellow),
                    cell(guests, 6, COLORS.magenta if guests != "0" else COLORS.gray),
                    cell(
                        missing_title,
                        8,
                        COLORS.yellow if missing_title != "0" else COLORS.gray,
                    ),
                    cell(companies, 9, COLORS.gray),
                    cell(offices, 7, COLORS.gray),
                ],
                [key, clean(padded[0])],
            )
        )
    return picker_emit(headers, widths, picker_rows)
