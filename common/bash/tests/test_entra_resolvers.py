import io
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.errors import AppError, GraphError  # noqa: E402
from entra_tool.graph_fields import USER_RESOLVE_FIELDS  # noqa: E402
from entra_tool.models import State  # noqa: E402
from entra_tool.resolvers import resolve_group, resolve_user  # noqa: E402


class ResolverTests(unittest.TestCase):
    def test_user_resolve_fields_are_minimal_identity_fields(self) -> None:
        self.assertEqual(
            USER_RESOLVE_FIELDS,
            ["id", "displayName", "userPrincipalName", "mail"],
        )

    def test_resolve_user_populates_state(self) -> None:
        state = State()
        with patch(
            "entra_tool.resolvers.graph_get",
            return_value={
                "id": "u1",
                "displayName": "Ada",
                "userPrincipalName": "ada@example.com",
            },
        ):
            resolve_user("ada@example.com", state)

        self.assertEqual(state.user_id, "u1")
        self.assertEqual(state.user_display_name, "Ada")
        self.assertEqual(state.user_upn, "ada@example.com")

    def test_resolve_user_raises_app_error_on_graph_failure(self) -> None:
        with patch("entra_tool.resolvers.graph_get", side_effect=GraphError("nope")):
            with self.assertRaisesRegex(AppError, "User not found"):
                resolve_user("missing@example.com", State())

    def test_resolve_group_by_guid_populates_state(self) -> None:
        state = State()
        group_id = "adfcf189-fd47-4a83-8e01-a0553e8365f3"
        with patch(
            "entra_tool.resolvers.graph_get",
            return_value={"id": group_id, "displayName": "Group", "mail": "g@example.com"},
        ) as graph_get:
            resolve_group(group_id, state)

        self.assertEqual(state.group_id, group_id)
        self.assertEqual(state.group_display_name, "Group")
        self.assertIn(f"/groups/{group_id}?", graph_get.call_args.args[0])

    def test_resolve_group_rejects_short_id_prefix(self) -> None:
        with self.assertRaisesRegex(AppError, "Short group id prefixes"):
            resolve_group("adfcf189", State())

    def test_resolve_group_by_exact_display_name(self) -> None:
        state = State()
        with patch(
            "entra_tool.resolvers.graph_get",
            return_value={"value": [{"id": "g1", "displayName": "Group", "mail": ""}]},
        ) as graph_get:
            resolve_group("Group", state)

        self.assertEqual(state.group_id, "g1")
        self.assertIn("displayName%20eq%20%27Group%27", graph_get.call_args.args[0])

    def test_resolve_group_duplicate_names_prints_matches_and_exits(self) -> None:
        with (
            patch(
                "entra_tool.resolvers.graph_get",
                return_value={
                    "value": [
                        {"id": "g1", "displayName": "Group"},
                        {"id": "g2", "displayName": "Group"},
                    ]
                },
            ),
            patch("sys.stderr", new_callable=io.StringIO) as stderr,
        ):
            with self.assertRaises(SystemExit):
                resolve_group("Group", State())

        self.assertIn("Multiple groups found", stderr.getvalue())
        self.assertIn("displayName\tmail\tid", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
