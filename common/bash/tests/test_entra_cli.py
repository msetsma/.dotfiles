import io
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.cli import parse_args, validate_options  # noqa: E402
from entra_tool.errors import AppError  # noqa: E402
from entra_tool.models import Options  # noqa: E402


class CliTests(unittest.TestCase):
    def test_parse_user_command_with_flags(self) -> None:
        opts = parse_args(["user", "ada@example.com", "--direct", "--tsv", "--color=never"])

        self.assertEqual(opts.target_type, "user")
        self.assertEqual(opts.identifier, "ada@example.com")
        self.assertEqual(opts.mode, "direct")
        self.assertTrue(opts.mode_explicit)
        self.assertTrue(opts.tsv_output)
        self.assertEqual(opts.color_mode, "never")

    def test_parse_search_aliases_to_search_users_with_initial_query(self) -> None:
        opts = parse_args(["search", "users", "Ada"])

        self.assertEqual(opts.target_type, "search-users")
        self.assertEqual(opts.initial_query, "Ada")

    def test_parse_reports_treats_email_as_identifier(self) -> None:
        opts = parse_args(["reports", "manager@example.com"])

        self.assertEqual(opts.target_type, "reports")
        self.assertEqual(opts.identifier, "manager@example.com")
        self.assertEqual(opts.initial_query, "")

    def test_parse_reports_treats_name_as_initial_query(self) -> None:
        opts = parse_args(["reports", "Manager Name"])

        self.assertEqual(opts.target_type, "reports")
        self.assertEqual(opts.identifier, "")
        self.assertEqual(opts.initial_query, "Manager Name")

    def test_parse_compare_group_identifiers(self) -> None:
        opts = parse_args(["compare", "groups", "A", "B", "--full"])

        self.assertEqual(opts.target_type, "compare-groups")
        self.assertEqual(opts.left_identifier, "A")
        self.assertEqual(opts.right_identifier, "B")
        self.assertTrue(opts.full_output)

    def test_parse_cache_refresh_all(self) -> None:
        opts = parse_args(["cache", "refresh", "--all"])

        self.assertEqual(opts.target_type, "cache-refresh")
        self.assertTrue(opts.cache_users)
        self.assertTrue(opts.cache_groups)
        self.assertTrue(opts.cache_scope_explicit)

    def test_help_prints_usage_and_exits(self) -> None:
        with patch("sys.stdout", new_callable=io.StringIO) as stdout:
            with self.assertRaises(SystemExit):
                parse_args(["--help"])

        self.assertIn("Usage:", stdout.getvalue())

    def test_validate_rejects_tsv_search(self) -> None:
        opts = Options(target_type="search-users", tsv_output=True)

        with self.assertRaisesRegex(AppError, "--tsv is not supported"):
            validate_options(opts)

    def test_validate_rejects_cache_status_scope(self) -> None:
        opts = Options(target_type="cache-status", cache_scope_explicit=True)

        with self.assertRaisesRegex(AppError, "cache status does not support"):
            validate_options(opts)

    def test_validate_rejects_dept_mode(self) -> None:
        opts = Options(target_type="dept", mode_explicit=True)

        with self.assertRaisesRegex(AppError, "--direct and --transitive"):
            validate_options(opts)

    def test_validate_accepts_compare_refresh_cache(self) -> None:
        validate_options(Options(target_type="compare-users", refresh_cache=True))


if __name__ == "__main__":
    unittest.main()
