import io
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.app import (  # noqa: E402
    main,
    need_command,
    requires_fzf,
    run,
)
from entra_tool.errors import AppError  # noqa: E402
from entra_tool.models import Options  # noqa: E402


class AppTests(unittest.TestCase):
    def test_need_command_raises_app_error_when_missing(self) -> None:
        with patch("entra_tool.app.shutil.which", return_value=None):
            with self.assertRaisesRegex(AppError, "Missing required command"):
                need_command("az")

    def test_cache_status_does_not_require_az(self) -> None:
        with (
            patch("entra_tool.app.print_cache_status") as status,
            patch("entra_tool.app.need_command") as need,
        ):
            run(Options(target_type="cache-status", color_mode="never"))

        status.assert_called_once()
        need.assert_not_called()

    def test_search_command_requires_fzf(self) -> None:
        with patch("entra_tool.app.need_command") as need:
            with patch("entra_tool.app.run_search_command"):
                run(Options(target_type="search-users", color_mode="never"))

        self.assertEqual([call.args[0] for call in need.call_args_list], ["az", "fzf"])

    def test_requires_fzf_for_picker_backed_commands(self) -> None:
        self.assertTrue(requires_fzf(Options(target_type="search-users")))
        self.assertTrue(requires_fzf(Options(target_type="compare")))
        self.assertTrue(requires_fzf(Options(target_type="reports")))
        self.assertTrue(
            requires_fzf(
                Options(
                    target_type="compare-users",
                    left_identifier="a@example.com",
                )
            )
        )
        self.assertFalse(
            requires_fzf(
                Options(
                    target_type="compare-users",
                    left_identifier="a@example.com",
                    right_identifier="b@example.com",
                )
            )
        )
        self.assertFalse(
            requires_fzf(Options(target_type="reports", identifier="manager@example.com"))
        )

    def test_main_returns_one_and_prints_app_error(self) -> None:
        with (
            patch("entra_tool.app.parse_args", side_effect=AppError("bad input")),
            patch("sys.stderr", new_callable=io.StringIO) as stderr,
        ):
            self.assertEqual(main(["bad"]), 1)

        self.assertIn("Error: bad input", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
