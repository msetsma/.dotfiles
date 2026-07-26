import io
import sys
import unittest
from unittest.mock import patch
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.compare_commands import (  # noqa: E402
    compare_groups,
    compare_users,
)
from entra_tool.compare_selection import (  # noqa: E402
    compare_group_from_picker_parts,
    compare_user_from_picker_parts,
    pick_compare_kind,
    select_compare_user_subjects,
)
from entra_tool.errors import AppError  # noqa: E402
from entra_tool.models import CompareSubject, Options  # noqa: E402


def opts(**kwargs) -> Options:
    values = {"target_type": "compare-users"}
    values.update(kwargs)
    return Options(**values)


class CompareCommandTests(unittest.TestCase):
    def test_pick_compare_kind_returns_selected_kind(self) -> None:
        with patch("entra_tool.compare_selection.run_fzf", return_value="row\tgroups\tGroups\t"):
            self.assertEqual(pick_compare_kind(), "groups")

    def test_picker_part_helpers_ignore_header_rows(self) -> None:
        with patch("sys.stderr", new_callable=io.StringIO):
            self.assertIsNone(compare_user_from_picker_parts(["row", "__id"]))
            self.assertIsNone(compare_group_from_picker_parts(["row", "__id"]))

    def test_picker_part_helpers_build_subjects(self) -> None:
        self.assertEqual(
            compare_user_from_picker_parts(["row", "u1", "Ada", "ada@example.com"]),
            CompareSubject("user", "u1", "Ada", "ada@example.com"),
        )
        self.assertEqual(
            compare_group_from_picker_parts(["row", "g1", "Group", "g@example.com"]),
            CompareSubject("group", "g1", "Group", "g@example.com"),
        )

    def test_select_compare_user_subjects_rejects_same_user(self) -> None:
        same = CompareSubject("user", "u1", "Ada", "ada@example.com")
        with patch("entra_tool.compare_selection.compare_user_from_identifier", return_value=same):
            with self.assertRaisesRegex(AppError, "different users"):
                select_compare_user_subjects(
                    opts(left_identifier="ada@example.com", right_identifier="ada@example.com")
                )

    def test_compare_users_prints_shared_and_different_groups(self) -> None:
        selected = (
            CompareSubject("user", "u1", "Ada", "ada@example.com"),
            CompareSubject("user", "u2", "Grace", "grace@example.com"),
        )
        with (
            patch("entra_tool.compare_commands.select_compare_user_subjects", return_value=selected),
            patch(
                "entra_tool.compare_commands.fetch_group_rows_for_user_id",
                side_effect=[
                    [["Shared", "", "g1"], ["Only Ada", "", "g2"]],
                    [["Shared", "", "g1"], ["Only Grace", "", "g3"]],
                ],
            ),
            patch("sys.stdout", new_callable=io.StringIO) as stdout,
        ):
            compare_users(opts())

        output = stdout.getvalue()
        self.assertIn("Shared groups", output)
        self.assertIn("Only Ada", output)
        self.assertIn("Only Grace", output)

    def test_compare_groups_enriches_user_rows(self) -> None:
        selected = (
            CompareSubject("group", "g1", "Group A"),
            CompareSubject("group", "g2", "Group B"),
        )
        with (
            patch("entra_tool.compare_commands.select_compare_group_subjects", return_value=selected),
            patch(
                "entra_tool.compare_commands.fetch_user_rows_for_group_id",
                side_effect=[
                    [["Shared", "", "", "u1"], ["Only A", "", "", "u2"]],
                    [["Shared", "", "", "u1"], ["Only B", "", "", "u3"]],
                ],
            ),
            patch("entra_tool.compare_commands.add_manager_details_to_user_rows", side_effect=lambda rows: rows),
            patch("sys.stdout", new_callable=io.StringIO) as stdout,
        ):
            compare_groups(opts(target_type="compare-groups"))

        self.assertIn("Shared users", stdout.getvalue())


if __name__ == "__main__":
    unittest.main()
