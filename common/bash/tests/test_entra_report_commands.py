import io
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.errors import AppError  # noqa: E402
from entra_tool.models import Options, State  # noqa: E402
from entra_tool.report_commands import search_reports, write_report_rows_for_user  # noqa: E402


def opts() -> Options:
    return Options(target_type="reports", use_cache=False)


class ReportCommandTests(unittest.TestCase):
    def test_search_reports_raises_when_no_users_are_returned(self) -> None:
        with patch("entra_tool.report_commands.load_user_search_rows", return_value=([], False)):
            with self.assertRaisesRegex(AppError, "No users returned"):
                search_reports("direct", "", True, False, False, State(), opts())

    def test_search_reports_tsv_selection_builds_report_filename(self) -> None:
        state = State()
        rows = [["Ada", "ada@example.com", "", "u1"]]
        with (
            patch("entra_tool.report_commands.load_user_search_rows", return_value=(rows, True)),
            patch("entra_tool.report_commands.run_fzf", return_value="row\tu1\tAda\tada@example.com"),
            patch("entra_tool.report_commands.write_report_rows_for_user") as writer,
        ):
            search_reports("direct", "Ada", True, False, True, state, opts())

        self.assertEqual(state.user_id, "u1")
        self.assertEqual(writer.call_args.args[0], "ada_example_com.direct.reports.tsv")

    def test_write_report_rows_for_user_writes_tsv_rows(self) -> None:
        state = State(user_id="root")
        root = {
            "id": "root",
            "displayName": "Root",
            "userPrincipalName": "root@example.com",
            "jobTitle": "VP",
            "accountEnabled": True,
        }
        child = {
            "id": "child",
            "displayName": "Child",
            "userPrincipalName": "child@example.com",
            "mail": "child@example.com",
            "jobTitle": "Engineer",
            "department": "Data",
            "accountEnabled": True,
        }
        rows = [
            [0, "", "", "root", "Root", "root@example.com", "", "VP", "", True, 1, "Root"],
            [
                1,
                "root",
                "Root",
                "child",
                "Child",
                "child@example.com",
                "child@example.com",
                "Engineer",
                "Data",
                True,
                "",
                "Child",
            ],
        ]
        users = {"root": root, "child": child}
        with (
            patch("entra_tool.report_commands.fetch_report_user_json", return_value=root),
            patch("entra_tool.report_commands.collect_report_tree", return_value=(rows, users)),
            patch("entra_tool.report_commands.write_report_tsv") as write_tsv,
        ):
            write_report_rows_for_user("reports.tsv", True, "direct", state, opts())

        write_tsv.assert_called_once_with("reports.tsv", rows)

    def test_write_report_rows_for_user_prints_summary(self) -> None:
        state = State(user_id="root")
        root = {
            "id": "root",
            "displayName": "Root",
            "userPrincipalName": "root@example.com",
            "jobTitle": "VP",
            "accountEnabled": True,
        }
        rows = [[0, "", "", "root", "Root", "root@example.com", "", "VP", "", True, 0, "Root"]]
        users = {"root": root}
        with (
            patch("entra_tool.report_commands.fetch_report_user_json", return_value=root),
            patch("entra_tool.report_commands.collect_report_tree", return_value=(rows, users)),
            patch("sys.stdout", new_callable=io.StringIO) as stdout,
        ):
            write_report_rows_for_user("", False, "direct", state, opts())

        self.assertIn("User report hierarchy", stdout.getvalue())
        self.assertIn("Reports:", stdout.getvalue())


if __name__ == "__main__":
    unittest.main()
