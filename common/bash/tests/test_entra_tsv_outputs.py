import sys
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.tsv_outputs import (  # noqa: E402
    GROUP_MEMBERSHIP_HEADER,
    REPORT_HEADER,
    USER_MEMBERSHIP_HEADER,
    report_tsv_rows,
    write_group_membership_tsv,
    write_report_tsv,
    write_user_membership_tsv,
)


class TsvOutputTests(unittest.TestCase):
    def test_membership_headers_pin_external_column_order(self) -> None:
        self.assertEqual(
            GROUP_MEMBERSHIP_HEADER,
            [
                "displayName",
                "mail",
                "id",
                "mailEnabled",
                "securityEnabled",
                "groupTypes",
                "createdDateTime",
            ],
        )
        self.assertEqual(
            USER_MEMBERSHIP_HEADER,
            [
                "displayName",
                "userPrincipalName",
                "mail",
                "id",
                "accountEnabled",
                "managerDisplayName",
                "managerId",
            ],
        )

    def test_report_rows_map_visible_report_rows_to_tsv_columns(self) -> None:
        rows = [[0, "m1", "Manager", "u1", "Ada", "upn", "mail", "Title", "Dept", True, 3, "Ada"]]

        self.assertEqual(
            report_tsv_rows(rows),
            [[0, "m1", "Manager", "u1", "Ada", "mail", "Title", "Dept", 3]],
        )
        self.assertEqual(
            REPORT_HEADER,
            [
                "level",
                "managerId",
                "managerDisplayName",
                "id",
                "displayName",
                "mail",
                "jobTitle",
                "department",
                "directReportCount",
            ],
        )

    def test_write_helpers_delegate_with_sorted_rows_and_headers(self) -> None:
        group_rows = [["Zulu"], ["Alpha"]]
        user_rows = [["Zulu"], ["Alpha"]]
        report_rows = [[0, "", "", "u1", "Ada", "upn", "mail", "Title", "Dept", True, 0, "Ada"]]
        with patch("entra_tool.tsv_outputs.write_tsv") as write_tsv:
            write_group_membership_tsv("groups.tsv", group_rows)
            write_user_membership_tsv("users.tsv", user_rows)
            write_report_tsv("reports.tsv", report_rows)

        self.assertEqual(write_tsv.call_args_list[0].args[0], Path("groups.tsv"))
        self.assertEqual(write_tsv.call_args_list[0].args[1], [["Alpha"], ["Zulu"]])
        self.assertEqual(write_tsv.call_args_list[0].args[2], GROUP_MEMBERSHIP_HEADER)
        self.assertEqual(write_tsv.call_args_list[1].args[0], Path("users.tsv"))
        self.assertEqual(write_tsv.call_args_list[1].args[1], [["Alpha"], ["Zulu"]])
        self.assertEqual(write_tsv.call_args_list[1].args[2], USER_MEMBERSHIP_HEADER)
        self.assertEqual(write_tsv.call_args_list[2].args[0], Path("reports.tsv"))
        self.assertEqual(write_tsv.call_args_list[2].args[1][0][3], "u1")
        self.assertEqual(write_tsv.call_args_list[2].args[2], REPORT_HEADER)


if __name__ == "__main__":
    unittest.main()
