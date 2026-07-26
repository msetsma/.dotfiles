import io
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.errors import AppError, GraphError  # noqa: E402
from entra_tool.group_owners import print_group_owners  # noqa: E402
from entra_tool.membership_commands import (  # noqa: E402
    pick_group_then_show_users,
    pick_user_then_show_groups,
    write_group_rows_for_user,
    write_user_rows_for_group,
)
from entra_tool.models import Options, State  # noqa: E402


def opts(target_type: str = "user") -> Options:
    return Options(target_type=target_type)


class MembershipCommandTests(unittest.TestCase):
    def test_print_group_owners_handles_graph_failure(self) -> None:
        with (
            patch("entra_tool.group_owners.graph_get", side_effect=GraphError("denied")),
            patch("sys.stdout", new_callable=io.StringIO) as stdout,
        ):
            print_group_owners("g1", full_output=False)

        self.assertIn("Owners:", stdout.getvalue())
        self.assertIn("not available", stdout.getvalue())

    def test_print_group_owners_hides_extra_owners_without_full_output(self) -> None:
        owners = [
            {"displayName": f"Owner {index}", "userPrincipalName": f"o{index}@example.com"}
            for index in range(6)
        ]
        with (
            patch("entra_tool.group_owners.graph_get", return_value={"value": owners}),
            patch("sys.stdout", new_callable=io.StringIO) as stdout,
        ):
            print_group_owners("g1", full_output=False)

        output = stdout.getvalue()
        self.assertIn("Owner 0 <o0@example.com>", output)
        self.assertIn("1 more owner(s)", output)

    def test_pick_group_then_show_users_updates_state_and_delegates(self) -> None:
        state = State()
        with (
            patch("entra_tool.membership_commands.run_fzf", return_value="row\tg1\tGroup\tg@example.com"),
            patch("entra_tool.membership_commands.write_user_rows_for_group") as writer,
        ):
            pick_group_then_show_users([], "direct", state, opts())

        self.assertEqual(state.group_id, "g1")
        self.assertEqual(state.group_display_name, "Group")
        writer.assert_called_once()

    def test_pick_user_then_show_groups_updates_state_and_delegates(self) -> None:
        state = State()
        with (
            patch("entra_tool.membership_commands.run_fzf", return_value="row\tu1\tAda\tada@example.com"),
            patch("entra_tool.membership_commands.write_group_rows_for_user") as writer,
        ):
            pick_user_then_show_groups([], "direct", state, opts())

        self.assertEqual(state.user_id, "u1")
        self.assertEqual(state.user_upn, "ada@example.com")
        writer.assert_called_once()

    def test_write_group_rows_for_user_tsv_requires_output_path(self) -> None:
        with patch("entra_tool.membership_commands.fetch_group_rows_for_user_id", return_value=[]):
            with self.assertRaisesRegex(AppError, "TSV output path"):
                write_group_rows_for_user("", True, "direct", False, State(user_id="u1"), opts())

    def test_write_group_rows_for_user_writes_sorted_tsv(self) -> None:
        rows = [["Zulu", "", "z"], ["Alpha", "", "a"]]
        with (
            patch("entra_tool.membership_commands.fetch_group_rows_for_user_id", return_value=rows),
            patch("entra_tool.membership_commands.write_group_membership_tsv") as write_tsv,
        ):
            write_group_rows_for_user("out.tsv", True, "direct", False, State(user_id="u1"), opts())

        write_tsv.assert_called_once_with("out.tsv", rows)

    def test_write_user_rows_for_group_fzf_delegates_before_manager_lookup(self) -> None:
        with (
            patch("entra_tool.membership_commands.fetch_user_rows_for_group_id", return_value=[["Ada"]]),
            patch("entra_tool.membership_commands.pick_user_then_show_groups") as picker,
            patch("entra_tool.membership_commands.add_manager_details_to_user_rows") as managers,
        ):
            write_user_rows_for_group("", False, "direct", True, State(group_id="g1"), opts("group"))

        picker.assert_called_once()
        managers.assert_not_called()


if __name__ == "__main__":
    unittest.main()
