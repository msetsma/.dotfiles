from pathlib import Path
from typing import Any

from entra_tool.terminal import sorted_rows
from entra_tool.tsv import write_tsv


GROUP_MEMBERSHIP_HEADER = [
    "displayName",
    "mail",
    "id",
    "mailEnabled",
    "securityEnabled",
    "groupTypes",
    "createdDateTime",
]
USER_MEMBERSHIP_HEADER = [
    "displayName",
    "userPrincipalName",
    "mail",
    "id",
    "accountEnabled",
    "managerDisplayName",
    "managerId",
]
REPORT_HEADER = [
    "level",
    "managerId",
    "managerDisplayName",
    "id",
    "displayName",
    "mail",
    "jobTitle",
    "department",
    "directReportCount",
]


def write_group_membership_tsv(out: str, rows: list[list[Any]]) -> None:
    write_tsv(Path(out), sorted_rows(rows), GROUP_MEMBERSHIP_HEADER)


def write_user_membership_tsv(out: str, rows: list[list[Any]]) -> None:
    write_tsv(Path(out), sorted_rows(rows), USER_MEMBERSHIP_HEADER)


def report_tsv_rows(rows: list[list[Any]]) -> list[list[Any]]:
    return [
        [row[0], row[1], row[2], row[3], row[4], row[6], row[7], row[8], row[10]]
        for row in rows
    ]


def write_report_tsv(out: str, rows: list[list[Any]]) -> None:
    write_tsv(Path(out), report_tsv_rows(rows), REPORT_HEADER)
