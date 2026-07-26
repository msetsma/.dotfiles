import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.department_rows import (  # noqa: E402
    build_department_rows,
    count_values,
    top_values,
    users_for_department,
)


class DepartmentRowTests(unittest.TestCase):
    def test_build_department_rows_counts_status_and_distinct_values(self) -> None:
        rows = build_department_rows(
            [
                [
                    "Ada",
                    "ada@example.com",
                    "",
                    "1",
                    True,
                    "Member",
                    "Engineer",
                    "Data",
                    "Acme",
                    "Detroit",
                ],
                [
                    "Grace",
                    "grace@example.com",
                    "",
                    "2",
                    False,
                    "Guest",
                    "",
                    "Data",
                    "Acme",
                    "Remote",
                ],
                ["No Dept", "none@example.com", "", "3", True, "Member", "", "", "", ""],
            ]
        )

        self.assertEqual(rows[0], ["Data", "department:data", 2, 1, 1, 1, 1, 1, 2])
        self.assertEqual(
            rows[1], ["(No department)", "missing_department:", 1, 1, 0, 0, 1, 0, 0]
        )

    def test_users_for_department_filters_and_pads_matching_rows(self) -> None:
        rows = users_for_department(
            [
                ["Ada", "ada@example.com", "", "1", True, "Member", "Engineer", "Data"],
                ["Grace", "grace@example.com", "", "2", True, "Member", "Engineer", "IT"],
            ],
            "department:data",
        )

        self.assertEqual(len(rows), 1)
        self.assertEqual(
            rows[0][:8],
            ["Ada", "ada@example.com", "", "1", True, "Member", "Engineer", "Data"],
        )
        self.assertEqual(len(rows[0]), 10)

    def test_count_values_sorts_by_frequency_then_name_and_skips_empty(self) -> None:
        self.assertEqual(
            count_values(["Detroit", "", None, "Remote", "detroit", "Remote", "Remote"]),
            [("Remote", 3), ("Detroit", 1), ("detroit", 1)],
        )

    def test_top_values_formats_limited_counts(self) -> None:
        self.assertEqual(top_values(["A", "B", "A", "C"], limit=2), "A (2), B (1)")
        self.assertEqual(top_values(["", None]), "-")


if __name__ == "__main__":
    unittest.main()
