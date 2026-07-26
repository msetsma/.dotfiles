import json
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.cache_freshness import (  # noqa: E402
    cache_is_fresh,
    report_cache_entry_is_fresh,
)
from entra_tool.cache_paths import (  # noqa: E402
    cache_dir,
    group_search_cache_path,
    report_direct_reports_cache_path,
    search_cache_path,
)
from entra_tool.report_cache_store import (  # noqa: E402
    load_report_direct_reports_cache,
    save_report_direct_reports_cache,
)
from entra_tool.search_cache import save_search_cache  # noqa: E402
from entra_tool.tsv import read_tsv, tsv_value, write_tsv  # noqa: E402


class CacheTests(unittest.TestCase):
    def test_cache_dir_prefers_xdg_cache_home(self) -> None:
        with patch.dict(
            "os.environ",
            {"XDG_CACHE_HOME": "/tmp/xdg-cache", "HOME": "/tmp/home"},
            clear=True,
        ):
            self.assertEqual(cache_dir(), Path("/tmp/xdg-cache/entra_membership"))

    def test_cache_paths_preserve_existing_filenames(self) -> None:
        with patch.dict("os.environ", {"HOME": "/tmp/home"}, clear=True):
            self.assertEqual(
                search_cache_path(), Path("/tmp/home/.cache/entra_membership/search_users.tsv")
            )
            self.assertEqual(
                group_search_cache_path(),
                Path("/tmp/home/.cache/entra_membership/search_groups_v2.tsv"),
            )

    def test_tsv_value_serializes_none_and_bool_values(self) -> None:
        self.assertEqual(tsv_value(None), "")
        self.assertEqual(tsv_value(True), "true")
        self.assertEqual(tsv_value(False), "false")
        self.assertEqual(tsv_value(42), "42")

    def test_write_and_read_tsv(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "rows.tsv"
            write_tsv(path, [[True, None, "value"]], ["enabled", "empty", "name"])

            self.assertEqual(
                read_tsv(path),
                [["enabled", "empty", "name"], ["true", "", "value"]],
            )

    def test_save_search_cache_writes_rows_and_meta(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with patch.dict("os.environ", {"XDG_CACHE_HOME": tmp}, clear=True):
                cache_file = search_cache_path()
                meta_file = cache_file.with_suffix(".meta")

                save_search_cache([[True, "Ada"]], cache_file, meta_file)

                self.assertEqual(read_tsv(cache_file), [["true", "Ada"]])
                self.assertTrue(meta_file.is_file())

    def test_cache_is_fresh_requires_nonempty_cache_and_current_meta(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cache_file = Path(tmp) / "cache.tsv"
            meta_file = Path(tmp) / "cache.meta"
            cache_file.write_text("row\n")
            meta_file.write_text(f"{int(time.time())}\n")

            self.assertTrue(cache_is_fresh(meta_file, cache_file))

    def test_report_cache_loads_valid_dict_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with patch.dict("os.environ", {"XDG_CACHE_HOME": tmp}, clear=True):
                report_direct_reports_cache_path().parent.mkdir(parents=True)
                report_direct_reports_cache_path().write_text(json.dumps({"u1": {}}))

                self.assertEqual(load_report_direct_reports_cache(True, False), {"u1": {}})

                report_direct_reports_cache_path().write_text("[]")
                self.assertEqual(load_report_direct_reports_cache(True, False), {})

    def test_save_report_cache_round_trips_compact_json(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with patch.dict("os.environ", {"XDG_CACHE_HOME": tmp}, clear=True):
                save_report_direct_reports_cache({"u1": {"children": []}})

                self.assertEqual(
                    load_report_direct_reports_cache(True, False),
                    {"u1": {"children": []}},
                )

    def test_report_cache_entry_freshness_shape(self) -> None:
        self.assertFalse(report_cache_entry_is_fresh({}))
        self.assertFalse(report_cache_entry_is_fresh({"fetchedAt": "now", "children": []}))
        self.assertTrue(
            report_cache_entry_is_fresh(
                {"fetchedAt": int(time.time()), "children": []}
            )
        )


if __name__ == "__main__":
    unittest.main()
