from typing import Any

from entra_tool.terminal import clean, yn


def department_display(value: Any) -> str:
    value = str(value or "").strip()
    return value or "(No department)"


def department_key(value: Any) -> str:
    value = str(value or "").strip()
    return f"department:{value.casefold()}" if value else "missing_department:"


def department_sort_key(row: list[Any]) -> tuple[str, str]:
    display = clean(row[0])
    return ("~" if display == "(No department)" else display.casefold(), display)


def build_department_rows(user_rows: list[list[Any]]) -> list[list[Any]]:
    stats: dict[str, dict[str, Any]] = {}
    for row in user_rows:
        padded = list(row) + [""] * (10 - len(row))
        key = department_key(padded[7])
        stat = stats.setdefault(
            key,
            {
                "display": department_display(padded[7]),
                "users": 0,
                "enabled": 0,
                "disabled": 0,
                "guests": 0,
                "missing_title": 0,
                "companies": set(),
                "offices": set(),
            },
        )
        stat["users"] += 1
        if yn(padded[4]) == "N":
            stat["disabled"] += 1
        else:
            stat["enabled"] += 1
        if clean(padded[5]).casefold() == "guest":
            stat["guests"] += 1
        if not str(padded[6] or "").strip():
            stat["missing_title"] += 1
        if str(padded[8] or "").strip():
            stat["companies"].add(str(padded[8]).strip())
        if str(padded[9] or "").strip():
            stat["offices"].add(str(padded[9]).strip())

    rows = [
        [
            stat["display"],
            key,
            stat["users"],
            stat["enabled"],
            stat["disabled"],
            stat["guests"],
            stat["missing_title"],
            len(stat["companies"]),
            len(stat["offices"]),
        ]
        for key, stat in stats.items()
    ]
    return sorted(rows, key=department_sort_key)


def users_for_department(
    user_rows: list[list[Any]], selected_key: str
) -> list[list[Any]]:
    rows = []
    for row in user_rows:
        padded = list(row) + [""] * (10 - len(row))
        if department_key(padded[7]) == selected_key:
            rows.append(padded[:10])
    return rows


def count_values(values: list[Any]) -> list[tuple[str, int]]:
    counts: dict[str, int] = {}
    for value in values:
        cleaned = clean(value)
        if cleaned == "-":
            continue
        counts[cleaned] = counts.get(cleaned, 0) + 1
    return sorted(counts.items(), key=lambda item: (-item[1], item[0].casefold()))


def top_values(values: list[Any], limit: int = 5) -> str:
    counts = count_values(values)
    if not counts:
        return "-"
    return ", ".join(f"{value} ({count})" for value, count in counts[:limit])
