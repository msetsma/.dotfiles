import io
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.errors import GraphError  # noqa: E402
from entra_tool.managers import (  # noqa: E402
    add_manager_details_to_user_rows,
    chunks,
    fetch_user_manager_details,
    fetch_user_manager_details_batch,
    manager_lookup_missing_status,
)


class ManagerTests(unittest.TestCase):
    def test_manager_lookup_missing_status_matches_graph_not_found(self) -> None:
        self.assertTrue(manager_lookup_missing_status(404))
        self.assertFalse(manager_lookup_missing_status(403))

    def test_chunks_splits_values_by_size(self) -> None:
        self.assertEqual(chunks(["a", "b", "c"], 2), [["a", "b"], ["c"]])

    def test_fetch_user_manager_details_returns_empty_without_user_id(self) -> None:
        self.assertEqual(
            fetch_user_manager_details(""),
            {"managerDisplayName": "", "managerId": ""},
        )

    def test_fetch_user_manager_details_reads_graph_response(self) -> None:
        with patch(
            "entra_tool.managers.graph_get",
            return_value={"id": "m1", "displayName": "Manager"},
        ) as graph_get:
            self.assertEqual(
                fetch_user_manager_details("u1"),
                {"managerDisplayName": "Manager", "managerId": "m1"},
            )

        self.assertIn("/users/u1/manager", graph_get.call_args.args[0])

    def test_fetch_user_manager_details_batch_maps_successful_responses(self) -> None:
        with patch(
            "entra_tool.managers.graph_post",
            return_value={
                "responses": [
                    {"id": "0", "status": 200, "body": {"id": "m1", "displayName": "Manager"}},
                    {"id": "1", "status": 404, "body": {}},
                ]
            },
        ) as graph_post:
            result = fetch_user_manager_details_batch(["u1", "u2", "u1", ""])

        self.assertEqual(
            result,
            {
                "u1": {"managerDisplayName": "Manager", "managerId": "m1"},
                "u2": {"managerDisplayName": "", "managerId": ""},
            },
        )
        requests = graph_post.call_args.args[1]["requests"]
        self.assertEqual([request["url"] for request in requests], [
            "/users/u1/manager?$select=id,displayName",
            "/users/u2/manager?$select=id,displayName",
        ])

    def test_fetch_user_manager_details_batch_falls_back_on_batch_failure(self) -> None:
        with (
            patch("entra_tool.managers.graph_post", side_effect=GraphError("denied")),
            patch(
                "entra_tool.managers.fetch_user_manager_details",
                side_effect=[
                    {"managerDisplayName": "Manager 1", "managerId": "m1"},
                    {"managerDisplayName": "Manager 2", "managerId": "m2"},
                ],
            ),
            patch("sys.stderr", new_callable=io.StringIO),
        ):
            result = fetch_user_manager_details_batch(["u1", "u2"])

        self.assertEqual(
            result,
            {
                "u1": {"managerDisplayName": "Manager 1", "managerId": "m1"},
                "u2": {"managerDisplayName": "Manager 2", "managerId": "m2"},
            },
        )

    def test_add_manager_details_to_user_rows_inserts_manager_columns(self) -> None:
        with patch(
            "entra_tool.managers.fetch_user_manager_details_batch",
            return_value={"u1": {"managerDisplayName": "Manager", "managerId": "m1"}},
        ):
            rows = add_manager_details_to_user_rows(
                [["Ada", "ada@example.com", "", "u1", True, "extra"]]
            )

        self.assertEqual(
            rows,
            [["Ada", "ada@example.com", "", "u1", True, "Manager", "m1", "extra"]],
        )


if __name__ == "__main__":
    unittest.main()
