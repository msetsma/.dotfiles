from typing import Any

from entra_tool.terminal import (
    bool_color,
    cell,
    clean,
    date_value,
    display_width,
    fit,
    text_color,
    type_color,
    yn,
)
from entra_tool.terminal_colors import COLORS


def format_group_table(
    rows: list[list[Any]], full_output: bool, name_width_cap: int = 56
) -> str:
    formatted = []
    for row in rows:
        padded = list(row) + [""] * (7 - len(row))
        formatted.append(
            [
                fit(padded[0], name_width_cap, full_output),
                clean(padded[1]),
                clean(padded[2]),
                yn(padded[3]),
                yn(padded[4]),
                clean(padded[5]),
                date_value(padded[6]),
            ]
        )

    widths = [
        max([display_width("GROUP")] + [display_width(row[0]) for row in formatted]),
        max([display_width("MAIL")] + [display_width(row[1]) for row in formatted]),
        max([display_width("ID")] + [display_width(row[2]) for row in formatted]),
        7,
        6,
        max([display_width("TYPE")] + [display_width(row[5]) for row in formatted]),
        max([display_width("CREATED")] + [display_width(row[6]) for row in formatted]),
    ]
    lines = [
        "  ".join(
            [
                cell("GROUP", widths[0], COLORS.bold + COLORS.cyan),
                cell("MAIL", widths[1], COLORS.bold + COLORS.cyan),
                cell("ID", widths[2], COLORS.bold + COLORS.cyan),
                cell("MAIL_EN", widths[3], COLORS.bold + COLORS.cyan),
                cell("SEC_EN", widths[4], COLORS.bold + COLORS.cyan),
                cell("TYPE", widths[5], COLORS.bold + COLORS.cyan),
                cell("CREATED", widths[6], COLORS.bold + COLORS.cyan),
            ]
        ),
        "  ".join([cell("-" * width, width, COLORS.dim) for width in widths]),
    ]
    for (
        group,
        mail,
        object_id,
        mail_enabled,
        security_enabled,
        group_type,
        created,
    ) in formatted:
        lines.append(
            "  ".join(
                [
                    cell(group, widths[0]),
                    cell(mail, widths[1], text_color(mail, COLORS.blue)),
                    cell(object_id, widths[2], COLORS.gray),
                    cell(mail_enabled, widths[3], bool_color(mail_enabled)),
                    cell(security_enabled, widths[4], bool_color(security_enabled)),
                    cell(group_type, widths[5], type_color(group_type)),
                    cell(created, widths[6], COLORS.gray),
                ]
            )
        )
    return "\n".join(lines)
