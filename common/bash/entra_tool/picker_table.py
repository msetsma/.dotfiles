from entra_tool.terminal import cell, display_width
from entra_tool.terminal_colors import COLORS


def picker_emit(
    headers: list[str], widths: list[int], rows: list[tuple[list[str], list[str]]]
) -> str:
    header_row = [
        cell(header, width, COLORS.bold + COLORS.cyan)
        for header, width in zip(headers, widths)
    ]
    rule_row = [
        cell("-" * min(width, max(4, display_width(header))), width, COLORS.dim)
        for header, width in zip(headers, widths)
    ]
    lines = [
        "  ".join(header_row) + "\t__id\t__name\t__value",
        "  ".join(rule_row) + "\t\t\t",
    ]
    for visible, hidden in rows:
        lines.append("  ".join(visible) + "\t" + "\t".join(hidden))
    return "\n".join(lines) + "\n"
