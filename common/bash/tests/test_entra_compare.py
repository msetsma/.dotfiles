import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.compare import (  # noqa: E402
    compare_rows_by_object_id,
    compare_subject_label,
    dedupe_rows_by_object_id,
    row_map_by_object_id,
    rows_excluding_object_id,
)
from entra_tool.models import CompareSubject  # noqa: E402


class CompareTests(unittest.TestCase):
    def test_compare_subject_label_includes_detail_when_available(self) -> None:
        self.assertEqual(
            compare_subject_label(
                CompareSubject(
                    kind="user",
                    object_id="u1",
                    name="Ada",
                    detail="ada@example.com",
                )
            ),
            "Ada <ada@example.com>",
        )
        self.assertEqual(
            compare_subject_label(
                CompareSubject(kind="group", object_id="g1", name="Group", detail="")
            ),
            "Group",
        )

    def test_rows_excluding_object_id_filters_selected_id(self) -> None:
        rows = [["Ada", "u1"], ["Grace", "u2"]]

        self.assertEqual(rows_excluding_object_id(rows, 1, "u1"), [["Grace", "u2"]])
        self.assertIs(rows_excluding_object_id(rows, 1, ""), rows)

    def test_row_map_by_object_id_ignores_missing_ids(self) -> None:
        self.assertEqual(
            row_map_by_object_id([["Ada", "u1"], ["No ID", ""], ["Grace", "u2"]], 1),
            {"u1": ["Ada", "u1"], "u2": ["Grace", "u2"]},
        )

    def test_compare_rows_by_object_id_returns_sorted_shared_and_differences(self) -> None:
        shared, left_only, right_only = compare_rows_by_object_id(
            [["Zulu", "z"], ["Alpha", "a"], ["Shared", "s"]],
            [["Shared", "s"], ["Beta", "b"]],
            1,
        )

        self.assertEqual(shared, [["Shared", "s"]])
        self.assertEqual(left_only, [["Alpha", "a"], ["Zulu", "z"]])
        self.assertEqual(right_only, [["Beta", "b"]])

    def test_dedupe_rows_by_object_id_keeps_first_row(self) -> None:
        self.assertEqual(
            dedupe_rows_by_object_id(
                [["Ada", "ada@example.com", "", "u1"], ["Ada 2", "", "", "u1"]],
                3,
            ),
            [["Ada", "ada@example.com", "", "u1"]],
        )


if __name__ == "__main__":
    unittest.main()
