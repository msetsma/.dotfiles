import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.models import State  # noqa: E402
from entra_tool.output_paths import (  # noqa: E402
    group_users_tsv_path,
    reports_tsv_path,
    user_groups_tsv_path,
)


class OutputPathTests(unittest.TestCase):
    def test_generated_tsv_paths_use_stable_slugs(self) -> None:
        self.assertEqual(
            user_groups_tsv_path(State(user_upn="ada@example.com"), "direct"),
            "ada_example_com.direct.groups.tsv",
        )
        self.assertEqual(
            group_users_tsv_path(
                State(group_display_name="Data Science", group_id="abcdef123456"),
                "transitive",
            ),
            "data_science_abcdef12.transitive.users.tsv",
        )
        self.assertEqual(
            reports_tsv_path(State(user_upn="manager@example.com"), "direct"),
            "manager_example_com.direct.reports.tsv",
        )


if __name__ == "__main__":
    unittest.main()
