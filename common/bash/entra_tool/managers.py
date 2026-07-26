import sys
from typing import Any

from entra_tool.errors import GraphError
from entra_tool.graph import graph_get, graph_post, uri_encode
from entra_tool.rows import empty_manager_details, manager_details_from_obj
from entra_tool.terminal import clean


def warn(message: str) -> None:
    print(f"Warning: {message}", file=sys.stderr)


def manager_lookup_missing_status(status: int) -> bool:
    return status == 404


def fetch_user_manager_details(user_id: str) -> dict[str, str]:
    if not user_id:
        return empty_manager_details()
    try:
        obj = graph_get(
            f"https://graph.microsoft.com/v1.0/users/{uri_encode(user_id)}/manager?$select=id,displayName"
        )
    except GraphError:
        return empty_manager_details()
    return manager_details_from_obj(obj)


def chunks(values: list[str], size: int) -> list[list[str]]:
    return [values[index : index + size] for index in range(0, len(values), size)]


def fetch_user_manager_details_batch(user_ids: list[str]) -> dict[str, dict[str, str]]:
    unique_user_ids = list(dict.fromkeys(user_id for user_id in user_ids if user_id))
    managers = {user_id: empty_manager_details() for user_id in unique_user_ids}

    for batch_user_ids in chunks(unique_user_ids, 20):
        request_to_user_id = {
            str(index): user_id for index, user_id in enumerate(batch_user_ids)
        }
        body = {
            "requests": [
                {
                    "id": request_id,
                    "method": "GET",
                    "url": f"/users/{uri_encode(user_id)}/manager?$select=id,displayName",
                }
                for request_id, user_id in request_to_user_id.items()
            ]
        }
        try:
            batch = graph_post("https://graph.microsoft.com/v1.0/$batch", body)
        except GraphError as exc:
            warn(
                f"Manager batch lookup failed; falling back to individual lookups. {exc}"
            )
            for user_id in batch_user_ids:
                managers[user_id] = fetch_user_manager_details(user_id)
            continue

        responses = batch.get("responses") or []
        for response in responses:
            if not isinstance(response, dict):
                continue
            user_id = request_to_user_id.get(str(response.get("id")))
            response_body = response.get("body")
            status = response.get("status")
            if (
                not user_id
                or not isinstance(response_body, dict)
                or not isinstance(status, int)
            ):
                continue
            if 200 <= status < 300:
                managers[user_id] = manager_details_from_obj(response_body)
            elif not manager_lookup_missing_status(status):
                warn(
                    f"Manager lookup failed for user {user_id}: Graph batch response status {status}"
                )

    return managers


def add_manager_details_to_user_rows(rows: list[list[Any]]) -> list[list[Any]]:
    user_ids = []
    for row in rows:
        padded = list(row) + [""] * (5 - len(row))
        user_id = clean(padded[3])
        if user_id != "-":
            user_ids.append(user_id)

    managers = fetch_user_manager_details_batch(user_ids)
    enriched = []
    for row in rows:
        padded = list(row) + [""] * (5 - len(row))
        user_id = clean(padded[3])
        manager = managers.get(user_id, empty_manager_details())
        enriched.append(
            padded[:5]
            + [manager["managerDisplayName"], manager["managerId"]]
            + padded[5:]
        )
    return enriched
