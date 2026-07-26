from typing import Any

from entra_tool.cache_freshness import cache_is_fresh
from entra_tool.cache_paths import (
    group_search_cache_meta_path,
    group_search_cache_path,
    search_cache_meta_path,
    search_cache_path,
)
from entra_tool.graph import graph_get, uri_encode
from entra_tool.graph_fields import (
    GROUP_MEMBER_FIELDS,
    GROUP_SEARCH_FIELDS,
    REPORT_USER_FIELDS,
    USER_DETAIL_FIELDS,
    USER_SEARCH_FIELDS,
    select_fields,
)
from entra_tool.rows import group_row, search_user_row, user_row
from entra_tool.search_cache import save_search_cache
from entra_tool.tsv import read_tsv


def collect_paged_rows(url: str, row_builder) -> list[list[Any]]:
    rows: list[list[Any]] = []
    while url:
        page = graph_get(url)
        rows.extend(row_builder(item) for item in page.get("value") or [])
        url = page.get("@odata.nextLink") or ""
    return rows


def user_detail_select_fields() -> str:
    return select_fields(USER_DETAIL_FIELDS)


def fetch_user_detail(selected_user_id: str) -> dict[str, Any]:
    encoded = uri_encode(selected_user_id)
    return graph_get(
        f"https://graph.microsoft.com/v1.0/users/{encoded}?$select={user_detail_select_fields()}"
    )


def load_user_search_rows(
    use_cache: bool, refresh_cache: bool
) -> tuple[list[list[Any]], bool]:
    cache_file = search_cache_path()
    meta_file = search_cache_meta_path()
    if use_cache and not refresh_cache and cache_is_fresh(meta_file, cache_file):
        return read_tsv(cache_file), True

    url = f"https://graph.microsoft.com/v1.0/users?$select={select_fields(USER_SEARCH_FIELDS)}&$top=999"
    rows = collect_paged_rows(url, search_user_row)
    if use_cache:
        save_search_cache(rows, cache_file, meta_file)
    return rows, False


def load_group_search_rows(
    use_cache: bool, refresh_cache: bool
) -> tuple[list[list[Any]], bool]:
    cache_file = group_search_cache_path()
    meta_file = group_search_cache_meta_path()
    if use_cache and not refresh_cache and cache_is_fresh(meta_file, cache_file):
        return read_tsv(cache_file), True

    url = f"https://graph.microsoft.com/v1.0/groups?$select={select_fields(GROUP_SEARCH_FIELDS)}&$top=999"
    rows = collect_paged_rows(url, group_row)
    if use_cache:
        save_search_cache(rows, cache_file, meta_file)
    return rows, False


def fetch_group_rows_for_user_id(user_id: str, mode: str) -> list[list[Any]]:
    relationship = "transitiveMemberOf" if mode == "transitive" else "memberOf"
    url = f"https://graph.microsoft.com/v1.0/users/{uri_encode(user_id)}/{relationship}/microsoft.graph.group?$select={select_fields(GROUP_SEARCH_FIELDS)}&$top=999"
    return collect_paged_rows(url, group_row)


def fetch_user_rows_for_group_id(group_id: str, mode: str) -> list[list[Any]]:
    relationship = "transitiveMembers" if mode == "transitive" else "members"
    url = f"https://graph.microsoft.com/v1.0/groups/{uri_encode(group_id)}/{relationship}/microsoft.graph.user?$select={select_fields(GROUP_MEMBER_FIELDS)}&$top=999"
    return collect_paged_rows(url, user_row)


def report_user_select_fields() -> str:
    return select_fields(REPORT_USER_FIELDS)


def fetch_report_user_json(selected_user_id: str) -> dict[str, Any]:
    encoded = uri_encode(selected_user_id)
    return graph_get(
        f"https://graph.microsoft.com/v1.0/users/{encoded}?$select={report_user_select_fields()}"
    )


def fetch_direct_report_users(manager: dict[str, Any]) -> list[dict[str, Any]]:
    manager_id = manager.get("id") or ""
    if not manager_id:
        return []
    children: list[dict[str, Any]] = []
    url = f"https://graph.microsoft.com/v1.0/users/{uri_encode(manager_id)}/directReports/microsoft.graph.user?$select={report_user_select_fields()}&$top=999"
    while url:
        page = graph_get(url)
        for child in page.get("value") or []:
            if isinstance(child, dict):
                children.append(child)
        url = page.get("@odata.nextLink") or ""
    return children
