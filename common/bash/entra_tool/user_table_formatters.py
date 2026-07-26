from typing import Any

from entra_tool.terminal import (
    bool_color,
    cell,
    clean,
    display_width,
    fit,
    text_color,
    yn,
)
from entra_tool.terminal_colors import COLORS


def format_user_table(
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
                clean(padded[3]),
                yn(padded[4]),
                fit(padded[5], name_width_cap, full_output),
                clean(padded[6]),
            ]
        )

    widths = [
        max([display_width("USER")] + [display_width(row[0]) for row in formatted]),
        max([display_width("UPN")] + [display_width(row[1]) for row in formatted]),
        max([display_width("MAIL")] + [display_width(row[2]) for row in formatted]),
        max([display_width("ID")] + [display_width(row[3]) for row in formatted]),
        7,
        max([display_width("MANAGER")] + [display_width(row[5]) for row in formatted]),
        max(
            [display_width("MANAGER_ID")] + [display_width(row[6]) for row in formatted]
        ),
    ]
    lines = [
        "  ".join(
            [
                cell("USER", widths[0], COLORS.bold + COLORS.cyan),
                cell("UPN", widths[1], COLORS.bold + COLORS.cyan),
                cell("MAIL", widths[2], COLORS.bold + COLORS.cyan),
                cell("ID", widths[3], COLORS.bold + COLORS.cyan),
                cell("ENABLED", widths[4], COLORS.bold + COLORS.cyan),
                cell("MANAGER", widths[5], COLORS.bold + COLORS.cyan),
                cell("MANAGER_ID", widths[6], COLORS.bold + COLORS.cyan),
            ]
        ),
        "  ".join([cell("-" * width, width, COLORS.dim) for width in widths]),
    ]
    for user, upn, mail, object_id, enabled, manager, manager_id in formatted:
        lines.append(
            "  ".join(
                [
                    cell(user, widths[0]),
                    cell(upn, widths[1], text_color(upn, COLORS.blue)),
                    cell(mail, widths[2], text_color(mail, COLORS.blue)),
                    cell(object_id, widths[3], COLORS.gray),
                    cell(enabled, widths[4], bool_color(enabled)),
                    cell(manager, widths[5]),
                    cell(manager_id, widths[6], COLORS.gray),
                ]
            )
        )
    return "\n".join(lines)
