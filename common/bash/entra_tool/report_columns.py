from entra_tool.terminal import display_width


def report_display_order() -> list[str]:
    return ["LEVEL", "USER", "MAIL", "ID", "TITLE", "DEPT", "DIRECTS"]


def report_required_columns() -> list[str]:
    return ["LEVEL", "USER", "TITLE", "DIRECTS"]


def report_optional_columns() -> list[str]:
    return ["MAIL", "DEPT", "ID"]


def report_table_width(widths: dict[str, int], column_names: list[str]) -> int:
    return sum(widths[name] for name in column_names) + (2 * (len(column_names) - 1))


def report_content_width(records: list[dict[str, str]], name: str) -> int:
    return max(
        [display_width(name)] + [display_width(record[name]) for record in records]
    )


def report_column_width(
    records: list[dict[str, str]],
    name: str,
    minimums: dict[str, int],
    preferred_caps: dict[str, int],
    full_output: bool,
) -> int:
    width = report_content_width(records, name)
    if not full_output and name != "USER":
        width = min(width, preferred_caps.get(name, width))
    return max(width, minimums.get(name, display_width(name)))


def choose_report_columns(
    records: list[dict[str, str]],
    minimums: dict[str, int],
    preferred_caps: dict[str, int],
    max_width: int,
    full_output: bool,
) -> tuple[list[str], dict[str, int]]:
    if full_output:
        column_names = report_display_order()
        widths = {
            name: report_column_width(
                records, name, minimums, preferred_caps, full_output
            )
            for name in column_names
        }
        return column_names, widths

    selected = report_required_columns()
    widths = {
        name: report_column_width(records, name, minimums, preferred_caps, full_output)
        for name in selected
    }
    shrink_widths(widths, minimums, max_width, selected)

    for name in report_optional_columns():
        candidate_names = sorted(selected + [name], key=report_display_order().index)
        candidate_widths = dict(widths)
        candidate_widths[name] = report_column_width(
            records, name, minimums, preferred_caps, full_output
        )
        shrink_widths(candidate_widths, minimums, max_width, candidate_names)
        if report_table_width(candidate_widths, candidate_names) <= max_width:
            selected = candidate_names
            widths = candidate_widths

    return selected, widths


def shrink_widths(
    widths: dict[str, int],
    minimums: dict[str, int],
    max_width: int,
    column_names: list[str],
) -> None:
    shrink_order = ["TITLE", "MAIL", "DEPT", "ID"]
    total = report_table_width(widths, column_names)
    for name in shrink_order:
        if total <= max_width:
            return
        if name not in widths:
            continue
        available = widths[name] - minimums.get(name, display_width(name))
        if available <= 0:
            continue
        reduction = min(available, total - max_width)
        widths[name] -= reduction
        total -= reduction
