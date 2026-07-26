from typing import Any

from entra_tool.models import CompareSubject
from entra_tool.terminal import clean, sorted_rows


def compare_subject_label(subject: CompareSubject) -> str:
    detail = clean(subject.detail)
    if detail == "-":
        return clean(subject.name)
    return f"{clean(subject.name)} <{detail}>"


def rows_excluding_object_id(
    rows: list[list[Any]], id_index: int, object_id: str
) -> list[list[Any]]:
    if not object_id:
        return rows
    return [
        row
        for row in rows
        if clean((list(row) + [""] * (id_index + 1))[id_index]) != object_id
    ]


def row_map_by_object_id(rows: list[list[Any]], id_index: int) -> dict[str, list[Any]]:
    result: dict[str, list[Any]] = {}
    for row in rows:
        padded = list(row) + [""] * (id_index + 1)
        object_id = clean(padded[id_index])
        if object_id != "-":
            result[object_id] = row
    return result


def rows_for_ids(ids: set[str], row_map: dict[str, list[Any]]) -> list[list[Any]]:
    return sorted_rows(
        [row_map[object_id] for object_id in ids if object_id in row_map]
    )


def compare_rows_by_object_id(
    left_rows: list[list[Any]], right_rows: list[list[Any]], id_index: int
) -> tuple[list[list[Any]], list[list[Any]], list[list[Any]]]:
    left_map = row_map_by_object_id(left_rows, id_index)
    right_map = row_map_by_object_id(right_rows, id_index)
    left_ids = set(left_map)
    right_ids = set(right_map)
    shared_ids = left_ids & right_ids
    left_only_ids = left_ids - right_ids
    right_only_ids = right_ids - left_ids
    return (
        rows_for_ids(shared_ids, left_map),
        rows_for_ids(left_only_ids, left_map),
        rows_for_ids(right_only_ids, right_map),
    )


def dedupe_rows_by_object_id(rows: list[list[Any]], id_index: int) -> list[list[Any]]:
    seen: set[str] = set()
    unique_rows = []
    for row in rows:
        padded = list(row) + [""] * (id_index + 1)
        object_id = clean(padded[id_index])
        if object_id in seen:
            continue
        seen.add(object_id)
        unique_rows.append(row)
    return unique_rows
