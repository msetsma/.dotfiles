import os
import sys
import time
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.report_cache import (  # noqa: E402
    cache_direct_report_users,
    cached_direct_report_users,
    report_max_workers,
)
from entra_tool.report_rows import (  # noqa: E402
    build_visible_report_rows,
    report_has_title,
    report_is_enabled,
    report_queue_item,
)
from entra_tool.report_tree import collect_report_tree  # noqa: E402


class ReportTests(unittest.TestCase):
    def test_report_max_workers_clamps_environment_value(self) -> None:
        with patch.dict(os.environ, {"ENTRA_REPORTS_MAX_WORKERS": "20"}):
            self.assertEqual(report_max_workers(), 8)
        with patch.dict(os.environ, {"ENTRA_REPORTS_MAX_WORKERS": "0"}):
            self.assertEqual(report_max_workers(), 1)
        with patch.dict(os.environ, {"ENTRA_REPORTS_MAX_WORKERS": "not-a-number"}):
            self.assertEqual(report_max_workers(), 4)

    def test_report_queue_item_normalizes_missing_values(self) -> None:
        self.assertEqual(
            report_queue_item(
                {"id": "u1", "displayName": "Ada", "accountEnabled": None},
                2,
                "m1",
                "Manager",
            ),
            {
                "id": "u1",
                "level": 2,
                "managerId": "m1",
                "managerDisplayName": "Manager",
                "displayName": "Ada",
                "userPrincipalName": "",
                "mail": "",
                "jobTitle": "",
                "department": "",
                "accountEnabled": "",
            },
        )

    def test_report_visibility_requires_title_and_enabled_account(self) -> None:
        self.assertTrue(report_has_title({"jobTitle": "Engineer"}))
        self.assertFalse(report_has_title({"jobTitle": ""}))
        self.assertTrue(report_is_enabled({"accountEnabled": True}))
        self.assertFalse(report_is_enabled({"accountEnabled": False}))

    def test_cached_direct_report_users_returns_fresh_dict_children_only(self) -> None:
        cache = {
            "m1": {
                "fetchedAt": int(time.time()),
                "children": [{"id": "u1"}, "bad", {"id": "u2"}],
            }
        }

        self.assertEqual(
            cached_direct_report_users("m1", cache, use_cache=True, refresh_cache=False),
            [{"id": "u1"}, {"id": "u2"}],
        )
        self.assertIsNone(
            cached_direct_report_users("m1", cache, use_cache=False, refresh_cache=False)
        )
        self.assertIsNone(
            cached_direct_report_users("m1", cache, use_cache=True, refresh_cache=True)
        )

    def test_cache_direct_report_users_updates_cache_when_enabled(self) -> None:
        cache = {}
        with patch("entra_tool.report_cache.time.time", return_value=123):
            changed = cache_direct_report_users(
                "m1", [{"id": "u1"}], cache, use_cache=True
            )

        self.assertTrue(changed)
        self.assertEqual(cache, {"m1": {"fetchedAt": 123, "children": [{"id": "u1"}]}})
        self.assertFalse(cache_direct_report_users("m2", [], cache, use_cache=False))
        self.assertNotIn("m2", cache)

    def test_collect_report_tree_fetches_and_builds_visible_rows(self) -> None:
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
            "jobTitle": "Engineer",
            "accountEnabled": True,
        }
        with (
            patch("entra_tool.report_tree.load_report_direct_reports_cache", return_value={}),
            patch("entra_tool.report_tree.fetch_direct_report_users", return_value=[child]) as fetch,
            patch("entra_tool.report_tree.save_report_direct_reports_cache") as save_cache,
        ):
            rows, users = collect_report_tree("root", root, "direct", False, False)

        fetch.assert_called_once()
        save_cache.assert_not_called()
        self.assertEqual([row[3] for row in rows], ["root", "child"])
        self.assertEqual(sorted(users), ["child", "root"])

    def test_build_visible_report_rows_promotes_hidden_users_children(self) -> None:
        root = {
            "id": "root",
            "displayName": "Root",
            "jobTitle": "VP",
            "accountEnabled": True,
            "directReportCount": 2,
        }
        hidden_no_title = {
            "id": "hidden-title",
            "displayName": "Hidden No Title",
            "jobTitle": "",
            "accountEnabled": True,
            "directReportCount": 1,
        }
        hidden_disabled = {
            "id": "hidden-disabled",
            "displayName": "Hidden Disabled",
            "jobTitle": "Manager",
            "accountEnabled": False,
            "directReportCount": 1,
        }
        visible_a = {
            "id": "a",
            "displayName": "Ada",
            "jobTitle": "Engineer",
            "accountEnabled": True,
            "directReportCount": 0,
        }
        visible_b = {
            "id": "b",
            "displayName": "Grace",
            "jobTitle": "Engineer",
            "accountEnabled": True,
            "directReportCount": 0,
        }
        rows = build_visible_report_rows(
            "root",
            {
                "root": root,
                "hidden-title": hidden_no_title,
                "hidden-disabled": hidden_disabled,
                "a": visible_a,
                "b": visible_b,
            },
            {
                "root": [hidden_no_title, hidden_disabled],
                "hidden-title": [visible_a],
                "hidden-disabled": [visible_b],
            },
        )

        self.assertEqual([row[3] for row in rows], ["root", "b", "a"])
        self.assertEqual([row[0] for row in rows], [0, 1, 1])
        self.assertEqual(rows[1][11], "├── Grace")
        self.assertEqual(rows[2][11], "└── Ada")

    def test_build_visible_report_rows_starts_with_children_when_root_hidden(self) -> None:
        rows = build_visible_report_rows(
            "root",
            {
                "root": {
                    "id": "root",
                    "displayName": "Root",
                    "jobTitle": "",
                    "accountEnabled": True,
                },
                "child": {
                    "id": "child",
                    "displayName": "Child",
                    "jobTitle": "Engineer",
                    "accountEnabled": True,
                },
            },
            {"root": [{"id": "child", "displayName": "Child", "jobTitle": "Engineer", "accountEnabled": True}]},
        )

        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0][0], 0)
        self.assertEqual(rows[0][3], "child")
        self.assertEqual(rows[0][11], "└── Child")


if __name__ == "__main__":
    unittest.main()
