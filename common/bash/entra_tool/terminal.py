import shutil
import unicodedata
from typing import Any

from entra_tool.terminal_colors import COLORS


def clean(value: Any) -> str:
    if value is None or value == "" or value == "None" or value == "null":
        return "-"
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value).replace("\r", "")


def json_scalar(obj: dict[str, Any], key: str) -> str:
    return clean(obj.get(key))


def json_array(obj: dict[str, Any], key: str) -> str:
    value = obj.get(key) or []
    if not isinstance(value, list):
        return clean(value)
    joined = ", ".join(str(item) for item in value if item is not None)
    return joined or "-"


def char_width(char: str) -> int:
    code = ord(char)
    if (
        unicodedata.combining(char)
        or unicodedata.category(char) == "Cf"
        or 0xFE00 <= code <= 0xFE0F
        or 0x1F3FB <= code <= 0x1F3FF
    ):
        return 0
    if 0x1F1E6 <= code <= 0x1F1FF:
        return 1
    if unicodedata.east_asian_width(char) in ("F", "W"):
        return 2
    if 0x1F000 <= code <= 0x1FAFF or 0x2600 <= code <= 0x27BF:
        return 2
    return 1


def display_width(value: Any) -> int:
    total = 0
    join_next = False
    for char in str(value):
        if char == "\u200d":
            join_next = True
            continue
        next_width = char_width(char)
        if join_next and next_width == 2:
            join_next = False
            continue
        join_next = False
        total += next_width
    return total


def fit(value: Any, cap: int, full: bool = False) -> str:
    value = clean(value)
    if full or cap <= 0 or display_width(value) <= cap:
        return value
    out = ""
    used = 0
    join_next = False
    for char in value:
        if char == "\u200d":
            out += char
            join_next = True
            continue
        next_width = char_width(char)
        if join_next and next_width == 2:
            next_width = 0
        join_next = False
        if used + next_width > cap - 3:
            break
        out += char
        used += next_width
    return out + "..."


def terminal_width(default: int = 120) -> int:
    return shutil.get_terminal_size((default, 20)).columns


def cell(value: Any, target: int, color: str = "") -> str:
    value = clean(value)
    pad = max(0, target - display_width(value))
    suffix = COLORS.reset if color else ""
    return color + value + suffix + (" " * pad)


def yn(value: Any) -> str:
    value = clean(value).lower()
    if value == "true":
        return "Y"
    if value == "false":
        return "N"
    return "-"


def bool_color(value: str) -> str:
    return COLORS.green if value == "Y" else COLORS.yellow


def text_color(value: str, default: str) -> str:
    return COLORS.gray if clean(value) == "-" else default


def type_color(value: str) -> str:
    if value == "Unified":
        return COLORS.cyan
    if value == "DynamicMembership":
        return COLORS.magenta
    if value == "-":
        return COLORS.gray
    return ""


def date_value(value: Any) -> str:
    value = clean(value)
    return value if value == "-" else value[:10]


def sorted_rows(rows: list[list[Any]]) -> list[list[Any]]:
    return sorted(
        rows, key=lambda row: "\t".join(clean(value).casefold() for value in row)
    )
