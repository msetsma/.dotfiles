import json
import subprocess
from typing import Any
from urllib.parse import quote

from entra_tool.errors import GraphError


def uri_encode(value: str) -> str:
    return quote(value, safe="")


def odata_string_literal(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def graph_get(url: str) -> dict[str, Any]:
    result = subprocess.run(
        [
            "az",
            "rest",
            "--only-show-errors",
            "--method",
            "get",
            "--url",
            url,
            "-o",
            "json",
        ],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        raise GraphError(detail or f"az rest failed for {url}")
    try:
        return json.loads(result.stdout or "{}")
    except json.JSONDecodeError as exc:
        raise GraphError(f"az rest returned invalid JSON for {url}: {exc}") from exc


def graph_post(url: str, body: dict[str, Any]) -> dict[str, Any]:
    result = subprocess.run(
        [
            "az",
            "rest",
            "--only-show-errors",
            "--method",
            "post",
            "--url",
            url,
            "--headers",
            "Content-Type=application/json",
            "--body",
            json.dumps(body),
            "-o",
            "json",
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        raise GraphError(detail or f"az rest failed for {url}")
    try:
        return json.loads(result.stdout or "{}")
    except json.JSONDecodeError as exc:
        raise GraphError(f"az rest returned invalid JSON for {url}: {exc}") from exc
