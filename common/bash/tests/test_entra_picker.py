import io
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.errors import AppError  # noqa: E402
from entra_tool.picker import run_fzf, selected_hidden_value  # noqa: E402
from entra_tool.picker_formatters import format_picker_rows  # noqa: E402


class PickerTests(unittest.TestCase):
    def test_format_user_picker_rows_includes_hidden_selection_fields(self) -> None:
        output = format_picker_rows(
            "user",
            [["Ada Lovelace", "ada@example.com", "ada@example.com", "user-id", True]],
        )

        self.assertIn("USER", output)
        self.assertIn("ENABLED", output)
        self.assertIn("Ada Lovelace", output)
        self.assertIn("\tuser-id\tAda Lovelace\tada@example.com", output)

    def test_format_group_picker_rows_sorts_by_visible_row(self) -> None:
        output = format_picker_rows(
            "group",
            [
                ["Zulu Group", "", "z-id", True, True, "", ""],
                ["Alpha Group", "", "a-id", True, True, "", ""],
            ],
        )

        self.assertLess(output.index("Alpha Group"), output.index("Zulu Group"))

    def test_format_unknown_picker_kind_raises_app_error(self) -> None:
        with self.assertRaisesRegex(AppError, "unknown picker kind"):
            format_picker_rows("unknown", [])

    def test_run_fzf_returns_selected_row(self) -> None:
        completed = SimpleNamespace(returncode=0, stdout="selected\n")
        with patch("entra_tool.picker.subprocess.run", return_value=completed) as run:
            self.assertEqual(run_fzf("input", "Prompt > ", "Header", "Ada"), "selected")

        args = run.call_args.args[0]
        self.assertIn("--ansi", args)
        self.assertIn("--query=Ada", args)
        self.assertEqual(run.call_args.kwargs["input"], "input")

    def test_run_fzf_returns_none_on_cancel(self) -> None:
        completed = SimpleNamespace(returncode=130, stdout="")
        with (
            patch("entra_tool.picker.subprocess.run", return_value=completed),
            patch("sys.stderr", new_callable=io.StringIO),
        ):
            self.assertIsNone(run_fzf("input", "Prompt > ", "Header"))

    def test_selected_hidden_value_returns_hidden_field(self) -> None:
        self.assertEqual(selected_hidden_value(["visible", "id", "name"]), "id")

    def test_selected_hidden_value_rejects_header_and_missing_value(self) -> None:
        with patch("sys.stderr", new_callable=io.StringIO) as stderr:
            self.assertIsNone(selected_hidden_value(["visible", "__id", "__name"]))
            self.assertIsNone(selected_hidden_value(["visible"]))

        self.assertEqual(
            stderr.getvalue(),
            "No data row selected.\nNo data row selected.\n",
        )


if __name__ == "__main__":
    unittest.main()
