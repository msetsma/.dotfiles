import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.group_table_formatters import format_group_table  # noqa: E402
from entra_tool.terminal import (  # noqa: E402
    clean,
    display_width,
    fit,
    yn,
)
from entra_tool.terminal_colors import (  # noqa: E402
    Colors,
    set_colors,
    setup_color,
    styled,
)
from entra_tool.user_table_formatters import format_user_table  # noqa: E402


class FormatterTests(unittest.TestCase):
    def setUp(self) -> None:
        set_colors(Colors())

    def test_clean_normalizes_empty_values_and_booleans(self) -> None:
        self.assertEqual(clean(None), "-")
        self.assertEqual(clean(""), "-")
        self.assertEqual(clean("null"), "-")
        self.assertEqual(clean(True), "true")
        self.assertEqual(clean(False), "false")
        self.assertEqual(clean("a\rb"), "ab")

    def test_yn_converts_graph_bool_values(self) -> None:
        self.assertEqual(yn(True), "Y")
        self.assertEqual(yn(False), "N")
        self.assertEqual(yn("true"), "Y")
        self.assertEqual(yn("false"), "N")
        self.assertEqual(yn(None), "-")

    def test_fit_truncates_by_display_width(self) -> None:
        self.assertEqual(fit("abcdef", 5), "ab...")
        self.assertEqual(fit("abcdef", 5, full=True), "abcdef")
        self.assertEqual(fit("abc", 5), "abc")

    def test_display_width_handles_wide_characters(self) -> None:
        self.assertEqual(display_width("abc"), 3)
        self.assertEqual(display_width("表"), 2)

    def test_styled_uses_shared_color_state(self) -> None:
        set_colors(Colors(reset="R", green="G"))
        self.assertEqual(styled("value", "G"), "GvalueR")

    def test_setup_color_rejects_invalid_mode(self) -> None:
        with self.assertRaisesRegex(ValueError, "Invalid color mode: blue"):
            setup_color("blue")

    def test_format_group_table_contains_expected_columns_and_values(self) -> None:
        output = format_group_table(
            [
                [
                    "Data Science Practice",
                    "dsp@example.com",
                    "group-id",
                    True,
                    False,
                    "Unified",
                    "2026-01-02T03:04:05Z",
                ]
            ],
            full_output=True,
        )

        self.assertIn("GROUP", output)
        self.assertIn("MAIL_EN", output)
        self.assertIn("SEC_EN", output)
        self.assertIn("Data Science Practice", output)
        self.assertIn("group-id", output)
        self.assertIn("2026-01-02", output)

    def test_format_user_table_contains_enabled_and_manager_columns(self) -> None:
        output = format_user_table(
            [
                [
                    "Ada Lovelace",
                    "ada@example.com",
                    "ada@example.com",
                    "user-id",
                    True,
                    "Grace Hopper",
                    "manager-id",
                ]
            ],
            full_output=True,
        )

        self.assertIn("ENABLED", output)
        self.assertIn("MANAGER", output)
        self.assertIn("Ada Lovelace", output)
        self.assertIn("Y", output)
        self.assertIn("Grace Hopper", output)


if __name__ == "__main__":
    unittest.main()
