import csv
import tempfile
import time
from pathlib import Path
from typing import Any

from entra_tool.cache_paths import cache_dir
from entra_tool.tsv import tsv_value


def save_search_cache(rows: list[list[Any]], cache_file: Path, meta_file: Path) -> None:
    directory = cache_dir()
    try:
        directory.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(
            "w", delete=False, dir=directory, newline=""
        ) as tmp_cache:
            writer = csv.writer(tmp_cache, delimiter="\t", lineterminator="\n")
            writer.writerows([[tsv_value(value) for value in row] for row in rows])
            tmp_cache_path = Path(tmp_cache.name)
        with tempfile.NamedTemporaryFile("w", delete=False, dir=directory) as tmp_meta:
            tmp_meta.write(f"{int(time.time())}\n")
            tmp_meta_path = Path(tmp_meta.name)
        tmp_cache_path.replace(cache_file)
        tmp_meta_path.replace(meta_file)
    except OSError:
        return
