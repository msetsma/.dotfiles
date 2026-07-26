import os
import time
from typing import Any

from entra_tool.cache_freshness import report_cache_entry_is_fresh


def report_max_workers() -> int:
    value = os.environ.get("ENTRA_REPORTS_MAX_WORKERS", "4")
    try:
        parsed = int(value)
    except ValueError:
        parsed = 4
    return max(1, min(parsed, 8))


def cached_direct_report_users(
    manager_id: str, report_cache: dict[str, Any], use_cache: bool, refresh_cache: bool
) -> list[dict[str, Any]] | None:
    if not use_cache or refresh_cache:
        return None
    entry = report_cache.get(manager_id)
    if not report_cache_entry_is_fresh(entry):
        return None
    children = entry.get("children") if isinstance(entry, dict) else None
    if not isinstance(children, list):
        return None
    return [child for child in children if isinstance(child, dict)]


def cache_direct_report_users(
    manager_id: str,
    children: list[dict[str, Any]],
    report_cache: dict[str, Any],
    use_cache: bool,
) -> bool:
    if not use_cache:
        return False
    report_cache[manager_id] = {"fetchedAt": int(time.time()), "children": children}
    return True
