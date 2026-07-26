from typing import Any

from entra_tool.terminal_colors import COLORS


def print_kv(key: str, value: Any) -> None:
    print(f"{COLORS.dim}{key + ':':<15}{COLORS.reset} {value}")


def print_kv_continuation(value: Any) -> None:
    print(f"{COLORS.dim}{'':<15}{COLORS.reset} {value}")


def mode_note(mode: str) -> str:
    return {
        "direct": "direct membership only",
        "transitive": "direct plus nested membership",
    }.get(mode, "unknown membership mode")


def print_mode(mode: str) -> None:
    print_kv("Mode", f"{mode}  # {mode_note(mode)}")


def report_mode_note(mode: str) -> str:
    return {
        "direct": "direct reports only",
        "transitive": "direct reports plus every lower reporting level",
    }.get(mode, "unknown reports mode")


def print_report_mode(mode: str) -> None:
    print_kv("Mode", f"{mode}  # {report_mode_note(mode)}")


def print_group_legend() -> None:
    print(
        f"\n{COLORS.dim}Group legend:{COLORS.reset} MAIL_EN=mail enabled, SEC_EN=security enabled, TYPE=group type, CREATED=created date. Unified=Microsoft 365 group, DynamicMembership=rule-based membership. Long names are capped unless --full is used. Use --tsv for full exact values."
    )


def print_user_legend() -> None:
    print(
        f"\n{COLORS.dim}User legend:{COLORS.reset} ENABLED=account enabled. Long names are capped unless --full is used. Use --tsv for full exact values."
    )


def print_reports_legend() -> None:
    print(f"\n{COLORS.dim}Reports legend:{COLORS.reset}")
    print(f"  {COLORS.cyan}USER{COLORS.reset} is a tree and is never truncated.")
    print(
        f"  {COLORS.gray}LEVEL{COLORS.reset}=visible depth, {COLORS.gray}DIRECTS{COLORS.reset}=direct reports."
    )
    print("  Hidden: missing title or disabled account.")
    print("  Columns reveal as space allows; use --full or --tsv for complete values.")
