import sys
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.directory import (  # noqa: E402
    collect_paged_rows,
    fetch_direct_report_users,
    fetch_group_rows_for_user_id,
    fetch_user_detail,
    fetch_user_rows_for_group_id,
    load_group_search_rows,
    load_user_search_rows,
    user_detail_select_fields,
)
from entra_tool.graph_fields import USER_DETAIL_FIELDS, select_fields  # noqa: E402


class DirectoryTests(unittest.TestCase):
    def test_user_detail_fields_include_active_status(self) -> None:
        self.assertIn("accountEnabled", USER_DETAIL_FIELDS)
        self.assertIn("accountEnabled", user_detail_select_fields())
        self.assertEqual(select_fields(["id", "accountEnabled"]), "id,accountEnabled")

    def test_collect_paged_rows_follows_next_link(self) -> None:
        pages = [
            {"value": [{"id": "1"}], "@odata.nextLink": "next"},
            {"value": [{"id": "2"}]},
        ]
        with patch("entra_tool.directory.graph_get", side_effect=pages) as graph_get:
            rows = collect_paged_rows("first", lambda item: [item["id"]])

        self.assertEqual(rows, [["1"], ["2"]])
        self.assertEqual([call.args[0] for call in graph_get.call_args_list], ["first", "next"])

    def test_fetch_user_detail_builds_user_detail_url(self) -> None:
        with patch("entra_tool.directory.graph_get", return_value={"id": "u1"}) as graph_get:
            self.assertEqual(fetch_user_detail("u1"), {"id": "u1"})

        url = graph_get.call_args.args[0]
        self.assertIn("/users/u1?", url)
        self.assertIn("accountEnabled", url)
        self.assertIn("proxyAddresses", url)

    def test_load_user_search_rows_uses_fresh_cache(self) -> None:
        with (
            patch("entra_tool.directory.cache_is_fresh", return_value=True),
            patch("entra_tool.directory.read_tsv", return_value=[["Ada"]]) as read_tsv,
        ):
            rows, from_cache = load_user_search_rows(use_cache=True, refresh_cache=False)

        self.assertEqual(rows, [["Ada"]])
        self.assertTrue(from_cache)
        read_tsv.assert_called_once()

    def test_load_group_search_rows_refreshes_and_saves_cache(self) -> None:
        with (
            patch("entra_tool.directory.cache_is_fresh", return_value=False),
            patch("entra_tool.directory.collect_paged_rows", return_value=[["Group"]]) as collect,
            patch("entra_tool.directory.save_search_cache") as save,
        ):
            rows, from_cache = load_group_search_rows(use_cache=True, refresh_cache=True)

        self.assertEqual(rows, [["Group"]])
        self.assertFalse(from_cache)
        self.assertIn("/groups?", collect.call_args.args[0])
        save.assert_called_once()

    def test_fetch_group_rows_for_user_id_uses_mode_relationship(self) -> None:
        with patch("entra_tool.directory.collect_paged_rows", return_value=[]) as collect:
            fetch_group_rows_for_user_id("u1", "direct")
            fetch_group_rows_for_user_id("u1", "transitive")

        self.assertIn("/users/u1/memberOf/", collect.call_args_list[0].args[0])
        self.assertIn("/users/u1/transitiveMemberOf/", collect.call_args_list[1].args[0])

    def test_fetch_user_rows_for_group_id_uses_mode_relationship(self) -> None:
        with patch("entra_tool.directory.collect_paged_rows", return_value=[]) as collect:
            fetch_user_rows_for_group_id("g1", "direct")
            fetch_user_rows_for_group_id("g1", "transitive")

        self.assertIn("/groups/g1/members/", collect.call_args_list[0].args[0])
        self.assertIn("/groups/g1/transitiveMembers/", collect.call_args_list[1].args[0])

    def test_fetch_direct_report_users_paginates_and_filters_non_dict_children(self) -> None:
        pages = [
            {"value": [{"id": "u1"}, "bad"], "@odata.nextLink": "next"},
            {"value": [{"id": "u2"}]},
        ]
        with patch("entra_tool.directory.graph_get", side_effect=pages) as graph_get:
            rows = fetch_direct_report_users({"id": "manager"})

        self.assertEqual(rows, [{"id": "u1"}, {"id": "u2"}])
        self.assertEqual([call.args[0] for call in graph_get.call_args_list][1], "next")

    def test_fetch_direct_report_users_returns_empty_without_manager_id(self) -> None:
        self.assertEqual(fetch_direct_report_users({}), [])


if __name__ == "__main__":
    unittest.main()
