import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.rows import (  # noqa: E402
    group_row,
    manager_details_from_obj,
    search_user_row,
    user_row,
)


class RowTests(unittest.TestCase):
    def test_group_row_flattens_graph_group_fields(self) -> None:
        self.assertEqual(
            group_row(
                {
                    "displayName": "Engineering",
                    "mail": "eng@example.com",
                    "id": "group-id",
                    "mailEnabled": True,
                    "securityEnabled": False,
                    "groupTypes": ["Unified", "DynamicMembership"],
                    "createdDateTime": "2024-01-01T00:00:00Z",
                }
            ),
            [
                "Engineering",
                "eng@example.com",
                "group-id",
                True,
                False,
                "Unified;DynamicMembership",
                "2024-01-01T00:00:00Z",
            ],
        )

    def test_user_rows_default_missing_values_to_stable_placeholders(self) -> None:
        self.assertEqual(
            user_row({"displayName": "Ada", "accountEnabled": True}),
            ["Ada", "", "", "", True],
        )
        self.assertEqual(
            search_user_row({"displayName": "Ada", "userPrincipalName": "ada@example.com"}),
            ["Ada", "ada@example.com", "", "", None, "", "", "", "", ""],
        )

    def test_manager_details_are_stable_for_missing_values(self) -> None:
        self.assertEqual(
            manager_details_from_obj({"displayName": "Grace"}),
            {"managerDisplayName": "Grace", "managerId": ""},
        )


if __name__ == "__main__":
    unittest.main()
