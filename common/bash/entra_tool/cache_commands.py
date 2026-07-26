import time
from pathlib import Path
from typing import Any

from entra_tool.cache_freshness import (
    cache_created_at,
    cache_is_fresh,
    cache_ttl_seconds,
    human_age,
)
from entra_tool.cache_paths import (
    group_search_cache_meta_path,
    group_search_cache_path,
    search_cache_meta_path,
    search_cache_path,
)
from entra_tool.directory import load_group_search_rows, load_user_search_rows
from entra_tool.models import Options
from entra_tool.terminal import cell, display_width
from entra_tool.terminal_colors import COLORS


def cache_status_row(label: str, cache_file: Path, meta_file: Path) -> list[Any]:
    created_at = cache_created_at(meta_file)
    now = int(time.time())
    age = None if created_at is None else max(0, now - created_at)
    size = cache_file.stat().st_size if cache_file.is_file() else 0
    return [
        label,
        "fresh" if cache_is_fresh(meta_file, cache_file) else "stale",
        human_age(age),
        human_age(cache_ttl_seconds()),
        size,
        str(cache_file),
    ]


def print_cache_status() -> None:
    rows = [
        cache_status_row("users", search_cache_path(), search_cache_meta_path()),
        cache_status_row(
            "groups", group_search_cache_path(), group_search_cache_meta_path()
        ),
    ]
    headers = ["CACHE", "STATE", "AGE", "TTL", "BYTES", "PATH"]
    widths = [
        max(display_width(headers[index]), *(display_width(row[index]) for row in rows))
        for index in range(len(headers))
    ]
    print(
        "  ".join(
            cell(header, widths[index], COLORS.bold + COLORS.cyan)
            for index, header in enumerate(headers)
        )
    )
    print(
        "  ".join(
            cell("-" * widths[index], widths[index], COLORS.dim)
            for index in range(len(headers))
        )
    )
    for row in rows:
        color = COLORS.green if row[1] == "fresh" else COLORS.yellow
        print(
            "  ".join(
                [
                    cell(row[0], widths[0]),
                    cell(row[1], widths[1], color),
                    cell(row[2], widths[2]),
                    cell(row[3], widths[3]),
                    cell(row[4], widths[4]),
                    cell(row[5], widths[5], COLORS.gray),
                ]
            )
        )


def refresh_cache(opts: Options) -> None:
    if opts.cache_users:
        rows, _ = load_user_search_rows(True, True)
        print(f"users\trefreshed\t{len(rows)}")
    if opts.cache_groups:
        rows, _ = load_group_search_rows(True, True)
        print(f"groups\trefreshed\t{len(rows)}")
