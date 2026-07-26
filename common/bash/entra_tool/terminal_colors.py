import os
import sys
from dataclasses import dataclass


@dataclass
class Colors:
    reset: str = ""
    bold: str = ""
    dim: str = ""
    red: str = ""
    green: str = ""
    yellow: str = ""
    blue: str = ""
    magenta: str = ""
    cyan: str = ""
    gray: str = ""


COLORS = Colors()


def set_colors(colors: Colors) -> None:
    COLORS.reset = colors.reset
    COLORS.bold = colors.bold
    COLORS.dim = colors.dim
    COLORS.red = colors.red
    COLORS.green = colors.green
    COLORS.yellow = colors.yellow
    COLORS.blue = colors.blue
    COLORS.magenta = colors.magenta
    COLORS.cyan = colors.cyan
    COLORS.gray = colors.gray


def setup_color(color_mode: str) -> Colors:
    if color_mode == "always":
        use_color = True
    elif color_mode == "never":
        use_color = False
    elif color_mode == "auto":
        if os.environ.get("NO_COLOR"):
            use_color = False
        elif os.environ.get("CLICOLOR_FORCE", "0") != "0":
            use_color = True
        else:
            use_color = sys.stdout.isatty()
    else:
        raise ValueError(f"Invalid color mode: {color_mode}")

    if not use_color:
        return Colors()
    return Colors(
        reset="\033[0m",
        bold="\033[1m",
        dim="\033[2m",
        red="\033[31m",
        green="\033[32m",
        yellow="\033[33m",
        blue="\033[34m",
        magenta="\033[35m",
        cyan="\033[36m",
        gray="\033[90m",
    )


def styled(value: str, *styles: str) -> str:
    prefix = "".join(style for style in styles if style)
    return f"{prefix}{value}{COLORS.reset}" if prefix else value
