import io
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.cache_commands import cache_status_row, refresh_cache  # noqa: E402
from entra_tool.models import Options  # noqa: E402


class CacheCommandTests(unittest.TestCase):
    def test_cache_status_row_reports_fresh_file_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            cache_file = Path(tmpdir) / "cache.tsv"
            meta_file = Path(tmpdir) / "cache.meta"
            cache_file.write_text("data\n")
            meta_file.write_text("970\n")

            with (
                patch("entra_tool.cache_commands.time.time", return_value=1000),
                patch("entra_tool.cache_freshness.time.time", return_value=1000),
            ):
                row = cache_status_row("users", cache_file, meta_file)

        self.assertEqual(row[0], "users")
        self.assertEqual(row[1], "fresh")
        self.assertEqual(row[2], "30s")
        self.assertEqual(row[4], 5)

    def test_refresh_cache_prints_enabled_cache_counts(self) -> None:
        opts = Options(target_type="cache-refresh", cache_users=True, cache_groups=True)
        with (
            patch("entra_tool.cache_commands.load_user_search_rows", return_value=([1, 2], False)),
            patch("entra_tool.cache_commands.load_group_search_rows", return_value=([1], False)),
            patch("sys.stdout", new_callable=io.StringIO) as stdout,
        ):
            refresh_cache(opts)

        self.assertEqual(stdout.getvalue(), "users\trefreshed\t2\ngroups\trefreshed\t1\n")


if __name__ == "__main__":
    unittest.main()
