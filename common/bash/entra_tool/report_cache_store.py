import json
import tempfile
from pathlib import Path
from typing import Any

from entra_tool.cache_paths import cache_dir, report_direct_reports_cache_path


def load_report_direct_reports_cache(
    use_cache: bool, refresh_cache: bool
) -> dict[str, Any]:
    if not use_cache or refresh_cache:
        return {}
    cache_file = report_direct_reports_cache_path()
    if not cache_file.is_file() or cache_file.stat().st_size == 0:
        return {}
    try:
        data = json.loads(cache_file.read_text())
    except (json.JSONDecodeError, OSError):
        return {}
    return data if isinstance(data, dict) else {}


def save_report_direct_reports_cache(cache: dict[str, Any]) -> None:
    directory = cache_dir()
    try:
        directory.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile("w", delete=False, dir=directory) as tmp:
            json.dump(cache, tmp, separators=(",", ":"))
            tmp.write("\n")
            tmp_path = Path(tmp.name)
        tmp_path.replace(report_direct_reports_cache_path())
    except OSError:
        return
