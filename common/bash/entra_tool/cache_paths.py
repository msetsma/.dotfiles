import os
from pathlib import Path


def cache_dir() -> Path:
    if os.environ.get("XDG_CACHE_HOME"):
        return Path(os.environ["XDG_CACHE_HOME"]) / "entra_membership"
    if os.environ.get("HOME"):
        return Path(os.environ["HOME"]) / ".cache" / "entra_membership"
    return Path(os.environ.get("TMPDIR", "/tmp")) / "entra_membership-cache"


def search_cache_path() -> Path:
    return cache_dir() / "search_users.tsv"


def search_cache_meta_path() -> Path:
    return cache_dir() / "search_users.meta"


def group_search_cache_path() -> Path:
    return cache_dir() / "search_groups_v2.tsv"


def group_search_cache_meta_path() -> Path:
    return cache_dir() / "search_groups_v2.meta"


def report_direct_reports_cache_path() -> Path:
    return cache_dir() / "report_direct_reports_v1.json"
