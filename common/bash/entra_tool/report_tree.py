from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any

from entra_tool.report_cache_store import (
    load_report_direct_reports_cache,
    save_report_direct_reports_cache,
)
from entra_tool.directory import fetch_direct_report_users
from entra_tool.errors import AppError, GraphError
from entra_tool.report_cache import (
    cache_direct_report_users,
    cached_direct_report_users,
    report_max_workers,
)
from entra_tool.report_rows import (
    build_visible_report_rows,
    report_queue_item,
)


def add_report_children(
    current: dict[str, Any],
    raw_children: list[dict[str, Any]],
    next_frontier: list[dict[str, Any]],
    children_by_manager: dict[str, list[dict[str, Any]]],
) -> None:
    current_id = current.get("id") or ""
    current_level = int(current.get("level") or 0)
    children = [
        report_queue_item(
            child, current_level + 1, current_id, current.get("displayName") or ""
        )
        for child in raw_children
    ]
    current["directReportCount"] = len(children)
    children_by_manager[current_id] = children
    next_frontier.extend(children)


def collect_report_tree(
    root_id: str,
    root_json: dict[str, Any],
    mode: str,
    use_cache: bool,
    refresh_cache: bool,
) -> tuple[list[list[Any]], dict[str, dict[str, Any]]]:
    report_cache = load_report_direct_reports_cache(use_cache, refresh_cache)
    cache_dirty = False
    frontier = [report_queue_item(root_json, 0)]
    visited: set[str] = set()
    users: dict[str, dict[str, Any]] = {}
    children_by_manager: dict[str, list[dict[str, Any]]] = {}

    while frontier:
        next_frontier: list[dict[str, Any]] = []
        fetch_targets: list[dict[str, Any]] = []
        for current in frontier:
            current_id = current.get("id") or ""
            if not current_id or current_id in visited:
                continue
            visited.add(current_id)
            users[current_id] = current

            current_level = int(current.get("level") or 0)
            expand_children = not (mode == "direct" and current_level >= 1)
            if not expand_children:
                current["directReportCount"] = ""
                children_by_manager[current_id] = []
                continue

            cached_children = cached_direct_report_users(
                current_id, report_cache, use_cache, refresh_cache
            )
            if cached_children is not None:
                add_report_children(
                    current, cached_children, next_frontier, children_by_manager
                )
            else:
                fetch_targets.append(current)

        if fetch_targets:
            with ThreadPoolExecutor(max_workers=report_max_workers()) as executor:
                futures = {
                    executor.submit(fetch_direct_report_users, current): current
                    for current in fetch_targets
                }
                for future in as_completed(futures):
                    current = futures[future]
                    current_id = current.get("id") or ""
                    try:
                        raw_children = future.result()
                    except GraphError as exc:
                        raise AppError(
                            f"Direct reports lookup failed for user: {current.get('displayName', '')} <{current.get('userPrincipalName', '')}>"
                        ) from exc
                    cache_dirty = (
                        cache_direct_report_users(
                            current_id, raw_children, report_cache, use_cache
                        )
                        or cache_dirty
                    )
                    add_report_children(
                        current, raw_children, next_frontier, children_by_manager
                    )

        frontier = next_frontier

    rows = build_visible_report_rows(root_id, users, children_by_manager)
    if cache_dirty:
        save_report_direct_reports_cache(report_cache)
    return rows, users
