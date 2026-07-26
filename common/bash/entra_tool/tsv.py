import csv
from pathlib import Path
from typing import Any


def read_tsv(path: Path) -> list[list[str]]:
    with path.open(newline="") as handle:
        return list(csv.reader(handle, delimiter="\t"))


def tsv_value(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def write_tsv(
    path: Path, rows: list[list[Any]], header: list[str] | None = None
) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        if header is not None:
            writer.writerow(header)
        writer.writerows([[tsv_value(value) for value in row] for row in rows])
