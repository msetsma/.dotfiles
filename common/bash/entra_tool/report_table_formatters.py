from typing import Any

from entra_tool.report_columns import choose_report_columns
from entra_tool.terminal import (
    cell,
    clean,
    fit,
    terminal_width,
    text_color,
)
from entra_tool.terminal_colors import COLORS


def report_column_color(name: str, value: str) -> str:
    if name == "USER":
        return COLORS.bold
    if name == "LEVEL" or name == "ID" or name == "DIRECTS":
        return COLORS.gray
    if name == "MAIL":
        return text_color(value, COLORS.blue)
    if name == "TITLE":
        return text_color(value, COLORS.green)
    if name == "DEPT":
        return text_color(value, COLORS.magenta)
    return ""


def format_reports_table(
    rows: list[list[Any]],
    full_output: bool,
    name_width_cap: int = 48,
    max_width: int | None = None,
) -> str:
    max_width = max_width or terminal_width()
    minimums = {
        "LEVEL": 5,
        "USER": 18,
        "MAIL": 16,
        "ID": 8,
        "TITLE": 12,
        "DEPT": 8,
        "DIRECTS": 7,
    }
    preferred_caps = {"MAIL": 30, "ID": 36, "TITLE": 30, "DEPT": 18}
    records: list[dict[str, str]] = []

    for row in rows:
        padded = list(row) + [""] * (12 - len(row))
        user_value = padded[11] or padded[4]
        record = {
            "LEVEL": clean(padded[0]),
            "USER": clean(user_value),
            "MAIL": clean(padded[6]),
            "ID": clean(padded[3]),
            "TITLE": clean(padded[7]),
            "DEPT": clean(padded[8]),
            "DIRECTS": clean(padded[10]),
        }
        records.append(record)

    column_names, widths = choose_report_columns(
        records, minimums, preferred_caps, max_width, full_output
    )

    lines = [
        "  ".join(
            [
                cell(name, widths[name], COLORS.bold + COLORS.cyan)
                for name in column_names
            ]
        ),
        "  ".join(
            [
                cell("-" * widths[name], widths[name], COLORS.dim)
                for name in column_names
            ]
        ),
    ]
    for record in records:
        lines.append(
            "  ".join(
                [
                    cell(
                        record[name]
                        if name == "USER"
                        else fit(record[name], widths[name], full_output),
                        widths[name],
                        report_column_color(name, record[name]),
                    )
                    for name in column_names
                ]
            )
        )
    return "\n".join(lines)
