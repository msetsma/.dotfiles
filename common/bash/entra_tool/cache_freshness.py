import os
import time
from pathlib import Path


def cache_ttl_seconds() -> int:
    value = os.environ.get("ENTRA_MEMBERSHIP_CACHE_TTL_SECONDS", "86400")
    return int(value) if value.isdigit() else 86400


def cache_is_fresh(meta_file: Path, cache_file: Path) -> bool:
    if not cache_file.is_file() or cache_file.stat().st_size == 0:
        return False
    if not meta_file.is_file() or meta_file.stat().st_size == 0:
        return False
    try:
        created = int(meta_file.read_text().splitlines()[0])
    except (IndexError, ValueError, OSError):
        return False
    age = int(time.time()) - created
    return 0 <= age < cache_ttl_seconds()


def cache_created_at(meta_file: Path) -> int | None:
    try:
        return int(meta_file.read_text().splitlines()[0])
    except (IndexError, ValueError, OSError):
        return None


def human_age(seconds: int | None) -> str:
    if seconds is None:
        return "-"
    if seconds < 60:
        return f"{seconds}s"
    minutes = seconds // 60
    if minutes < 60:
        return f"{minutes}m"
    hours = minutes // 60
    if hours < 48:
        return f"{hours}h"
    return f"{hours // 24}d"


def report_cache_entry_is_fresh(entry: object) -> bool:
    if not isinstance(entry, dict):
        return False
    fetched_at = entry.get("fetchedAt")
    children = entry.get("children")
    if not isinstance(fetched_at, int) or not isinstance(children, list):
        return False
    age = int(time.time()) - fetched_at
    return 0 <= age < cache_ttl_seconds()
