import io
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.errors import AppError, GraphError  # noqa: E402
from entra_tool.department_commands import search_departments  # noqa: E402
from entra_tool.group_detail import (  # noqa: E402
    GROUP_DETAIL_FIELDS,
    GROUP_ROLE_ASSIGNMENT_FIELD,
    fetch_group_detail,
)
from entra_tool.models import Options, State  # noqa: E402
from entra_tool.search_commands import (  # noqa: E402
    search_groups,
    search_users,
    show_selected_user_report,
)


def opts(target_type: str = "search-users") -> Options:
    return Options(target_type=target_type)


class SearchCommandTests(unittest.TestCase):
    def test_group_detail_field_sets_keep_role_assignment_optional(self) -> None:
        self.assertIn("proxyAddresses", GROUP_DETAIL_FIELDS)
        self.assertNotIn(GROUP_ROLE_ASSIGNMENT_FIELD, GROUP_DETAIL_FIELDS)

    def test_show_selected_user_report_enriches_manager_and_delegates(self) -> None:
        state = State()
        with (
            patch(
                "entra_tool.search_commands.fetch_user_detail",
                return_value={"id": "u1", "displayName": "Ada", "userPrincipalName": "ada@example.com"},
            ),
            patch(
                "entra_tool.search_commands.fetch_user_manager_details",
                return_value={"managerDisplayName": "Manager", "managerId": "m1"},
            ),
            patch(
                "entra_tool.search_commands.fetch_group_rows_for_user_id",
                return_value=[["Group"]],
            ),
            patch("entra_tool.search_commands.print_user_details") as details,
            patch("entra_tool.search_commands.print_group_rows_for_user") as printer,
        ):
            show_selected_user_report("u1", "direct", state, opts())

        self.assertEqual(state.user_id, "u1")
        self.assertEqual(details.call_args.args[0]["managerDisplayName"], "Manager")
        printer.assert_called_once()

    def test_search_users_raises_when_graph_returns_no_rows(self) -> None:
        with patch("entra_tool.search_commands.load_user_search_rows", return_value=([], False)):
            with self.assertRaisesRegex(AppError, "No users returned"):
                search_users("direct", "", True, False, State(), opts())

    def test_search_users_selection_opens_user_report(self) -> None:
        with (
            patch("entra_tool.search_commands.load_user_search_rows", return_value=([["Ada", "", "", "u1"]], True)),
            patch("entra_tool.search_commands.run_fzf", return_value="row\tu1\tAda\tada@example.com"),
            patch("entra_tool.search_commands.show_selected_user_report") as show,
        ):
            search_users("direct", "Ada", True, False, State(), opts())

        show.assert_called_once()
        self.assertEqual(show.call_args.args[0], "u1")

    def test_search_departments_selection_prints_department_users(self) -> None:
        rows = [["Ada", "ada@example.com", "", "u1", True, "Member", "Engineer", "Data", "Acme", "Detroit"]]
        enriched_rows = [
            ["Ada", "ada@example.com", "", "u1", True, "Manager", "m1", "Member", "Engineer", "Data", "Acme", "Detroit"]
        ]
        with (
            patch("entra_tool.department_commands.load_user_search_rows", return_value=(rows, True)),
            patch("entra_tool.department_commands.run_fzf", return_value="row\tdepartment:data\tData"),
            patch("entra_tool.department_commands.add_manager_details_to_user_rows", return_value=enriched_rows),
            patch("sys.stdout", new_callable=io.StringIO) as stdout,
        ):
            search_departments("Data", True, False, opts("dept"))

        output = stdout.getvalue()
        self.assertIn("Department details", output)
        self.assertIn("Data", output)

    def test_fetch_group_detail_falls_back_to_safe_url(self) -> None:
        with patch(
            "entra_tool.group_detail.graph_get",
            side_effect=[GraphError("forbidden"), {"id": "g1", "displayName": "Group"}],
        ) as graph_get:
            self.assertEqual(fetch_group_detail("g1")["id"], "g1")

        self.assertIn("isAssignableToRole", graph_get.call_args_list[0].args[0])
        self.assertNotIn("isAssignableToRole", graph_get.call_args_list[1].args[0])

    def test_search_groups_selection_opens_group_report(self) -> None:
        with (
            patch("entra_tool.search_commands.load_group_search_rows", return_value=([["Group", "", "g1"]], True)),
            patch("entra_tool.search_commands.run_fzf", return_value="row\tg1\tGroup\t"),
            patch("entra_tool.search_commands.show_selected_group_report") as show,
        ):
            search_groups("direct", "Group", True, False, State(), opts("search-groups"))

        self.assertEqual(show.call_args.args[0], "g1")


if __name__ == "__main__":
    unittest.main()
