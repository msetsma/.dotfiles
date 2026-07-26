import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from entra_tool.errors import GraphError  # noqa: E402
from entra_tool.graph import (  # noqa: E402
    graph_get,
    graph_post,
    odata_string_literal,
    uri_encode,
)


class GraphTests(unittest.TestCase):
    def test_uri_encode_escapes_graph_path_values(self) -> None:
        self.assertEqual(uri_encode("a b@example.com"), "a%20b%40example.com")

    def test_odata_string_literal_escapes_single_quotes(self) -> None:
        self.assertEqual(odata_string_literal("O'Hare"), "'O''Hare'")

    def test_graph_get_returns_json_and_builds_az_command(self) -> None:
        completed = SimpleNamespace(returncode=0, stdout='{"value": [1]}', stderr="")
        with patch("entra_tool.graph.subprocess.run", return_value=completed) as run:
            self.assertEqual(graph_get("https://graph.example/users"), {"value": [1]})

        args = run.call_args.args[0]
        self.assertEqual(args[:4], ["az", "rest", "--only-show-errors", "--method"])
        self.assertIn("https://graph.example/users", args)

    def test_graph_get_raises_graph_error_on_az_failure(self) -> None:
        completed = SimpleNamespace(returncode=1, stdout="", stderr="denied")
        with patch("entra_tool.graph.subprocess.run", return_value=completed):
            with self.assertRaisesRegex(GraphError, "denied"):
                graph_get("https://graph.example/users")

    def test_graph_get_raises_graph_error_on_invalid_json(self) -> None:
        completed = SimpleNamespace(returncode=0, stdout="{", stderr="")
        with patch("entra_tool.graph.subprocess.run", return_value=completed):
            with self.assertRaisesRegex(GraphError, "invalid JSON"):
                graph_get("https://graph.example/users")

    def test_graph_post_serializes_body(self) -> None:
        completed = SimpleNamespace(returncode=0, stdout='{"ok": true}', stderr="")
        with patch("entra_tool.graph.subprocess.run", return_value=completed) as run:
            self.assertEqual(
                graph_post("https://graph.example/batch", {"requests": []}),
                {"ok": True},
            )

        args = run.call_args.args[0]
        self.assertIn("--body", args)
        self.assertEqual(args[args.index("--body") + 1], '{"requests": []}')


if __name__ == "__main__":
    unittest.main()
