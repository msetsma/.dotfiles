import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.text import (  # noqa: E402
    is_guid,
    is_short_hex_id_prefix,
    looks_like_bad_guid,
    slugify,
)


class TextTests(unittest.TestCase):
    def test_is_guid_accepts_canonical_guid_only(self) -> None:
        self.assertTrue(is_guid("adfcf189-fd47-4a83-8e01-a0553e8365f3"))
        self.assertFalse(is_guid("adfcf189fd474a838e01a0553e8365f3"))
        self.assertFalse(is_guid("adfcf189-fd47-4a83-8e01-a0553e8365f3-extra"))

    def test_looks_like_bad_guid_detects_guid_with_trailing_text(self) -> None:
        self.assertTrue(looks_like_bad_guid("adfcf189-fd47-4a83-8e01-a0553e8365f3abc"))
        self.assertFalse(looks_like_bad_guid("adfcf189-fd47-4a83-8e01-a0553e8365f3"))

    def test_short_hex_id_prefix_requires_8_to_31_hex_chars(self) -> None:
        self.assertTrue(is_short_hex_id_prefix("adfcf189"))
        self.assertTrue(is_short_hex_id_prefix("adfcf189fd474a838e01a0553e8365"))
        self.assertFalse(is_short_hex_id_prefix("adfcf18"))
        self.assertFalse(is_short_hex_id_prefix("adfcf189fd474a838e01a0553e8365f3"))
        self.assertFalse(is_short_hex_id_prefix("adfcf189-not-hex"))

    def test_slugify_lowercases_and_collapses_non_alphanumerics(self) -> None:
        self.assertEqual(slugify("Data Science Practice!"), "data_science_practice")
        self.assertEqual(slugify("  A/B + C  "), "a_b_c")


if __name__ == "__main__":
    unittest.main()
