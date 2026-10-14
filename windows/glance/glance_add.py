# /// script
# requires-python = ">=3.12"
# dependencies = ["ruamel.yaml>=0.18"]
# ///
"""Manage glance bookmarks in bookmarks.yml (comments preserved).

Usage:
    uv run glance_add.py add <url> [--group G] [--title T] [--icon I]
    uv run glance_add.py rm <url>
    uv run glance_add.py ls

Glance watches included files, so the dashboard reloads on save.
"""

from __future__ import annotations

import argparse
import io
import logging
import os
import sys
import urllib.error
import urllib.request
from collections.abc import Sequence
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from ruamel.yaml import YAML

__all__ = [
    "Link",
    "add_link",
    "favicon_url",
    "fetch_title",
    "main",
    "poke_glance",
    "remove_link",
]

log = logging.getLogger("glance_add")

DEFAULT_FILE = Path(__file__).resolve().parent / "bookmarks.yml"
DEPLOYED_FILE = Path.home() / ".glance" / "bookmarks.yml"
DEFAULT_GROUP = "Links"
FAVICON_SERVICE = "https://www.google.com/s2/favicons?domain={host}&sz=64"
FETCH_TIMEOUT_S = 5
MAX_TITLE_BYTES = 256_000
USER_AGENT = "Mozilla/5.0 (glance_add)"


class BookmarkError(Exception):
    """Base error for bookmark operations."""


@dataclass(frozen=True)
class Link:
    title: str
    url: str
    icon: str

    def as_yaml(self) -> dict[str, str]:
        return {"title": self.title, "url": self.url, "icon": self.icon}


def validate_url(url: str) -> str:
    parsed = urlparse(url)
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        raise BookmarkError(f"not an http(s) URL: {url!r}")
    return url


def favicon_url(url: str) -> str:
    return FAVICON_SERVICE.format(host=urlparse(url).netloc)


class _TitleParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self._in_title = False
        self.title = ""

    def handle_starttag(
        self, tag: str, attrs: Sequence[tuple[str, str | None]]
    ) -> None:
        if tag == "title" and not self.title:
            self._in_title = True

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self._in_title = False

    def handle_data(self, data: str) -> None:
        if self._in_title:
            self.title += data


def parse_title(html: str) -> str | None:
    parser = _TitleParser()
    parser.feed(html)
    title = " ".join(parser.title.split())
    return title or None


def fetch_title(url: str) -> str | None:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=FETCH_TIMEOUT_S) as resp:
            charset = resp.headers.get_content_charset() or "utf-8"
            body = resp.read(MAX_TITLE_BYTES).decode(charset, errors="replace")
    except (urllib.error.URLError, TimeoutError, ValueError) as exc:
        log.warning("could not fetch title for %s: %s", url, exc)
        return None
    return parse_title(body)


def _bookmarks_widget(doc: Any) -> Any:
    for widget in doc:
        if widget.get("type") == "bookmarks":
            return widget
    raise BookmarkError("no 'type: bookmarks' widget found in file")


def _all_links(doc: Any) -> list[tuple[Any, Any]]:
    return [
        (group, link)
        for group in _bookmarks_widget(doc).get("groups", [])
        for link in group.get("links", [])
    ]


def add_link(doc: Any, group_title: str, link: Link) -> None:
    """Append link to group (created if missing). Mutates the round-trip doc in place
    so ruamel keeps comments and formatting."""
    if any(existing["url"] == link.url for _, existing in _all_links(doc)):
        raise BookmarkError(f"already bookmarked: {link.url}")
    groups = _bookmarks_widget(doc).setdefault("groups", [])
    group = next((g for g in groups if g.get("title") == group_title), None)
    if group is None:
        group = {"title": group_title, "links": []}
        groups.append(group)
        group = groups[-1]
    group.setdefault("links", []).append(link.as_yaml())


def remove_link(doc: Any, url: str) -> None:
    """Remove link by URL; drops the group if it ends up empty."""
    groups = _bookmarks_widget(doc).get("groups", [])
    for group, link in _all_links(doc):
        if link["url"] == url:
            group["links"].remove(link)
            if not group["links"]:
                groups.remove(group)
            return
    raise BookmarkError(f"not bookmarked: {url}")


def _yaml() -> YAML:
    yaml = YAML()
    yaml.indent(mapping=2, sequence=4, offset=2)
    yaml.width = 4096
    return yaml


def _load(path: Path) -> Any:
    try:
        return _yaml().load(path)
    except OSError as exc:
        raise BookmarkError(f"cannot read {path}: {exc}") from exc


def _normalize(text: str) -> str:
    """Flush the root list (ruamel's sequence offset indents it; glance includes want it
    at column 0) and strip CRs that ruamel keeps inside comments from CRLF files."""
    return "".join(line.removeprefix("  ") + "\n" for line in text.splitlines())


def _save(path: Path, doc: Any) -> None:
    buf = io.StringIO()
    _yaml().dump(doc, buf)
    # newline="\n": keep LF on Windows (text mode would write CRLF)
    path.write_text(_normalize(buf.getvalue()), encoding="utf-8", newline="\n")


def poke_glance(source: Path, deployed: Path = DEPLOYED_FILE) -> bool:
    """Re-create the dotter symlink so glance reloads.

    Glance watches the deployed dir; writes through a symlink land in the repo dir
    and fire no event there. Returns True if the link was re-created.
    """
    if not deployed.is_symlink() or deployed.resolve() != source.resolve():
        return False
    target = os.readlink(deployed)
    try:
        deployed.unlink()
        os.symlink(target, deployed)
    except OSError as exc:
        log.warning(
            "could not re-link %s (restart glance to reload): %s", deployed, exc
        )
        return False
    return True


def _write(path: Path, doc: Any) -> None:
    _save(path, doc)
    poke_glance(path)


def _cmd_add(args: argparse.Namespace) -> None:
    url = validate_url(args.url)
    title = args.title or fetch_title(url) or urlparse(url).netloc
    link = Link(title=title, url=url, icon=args.icon or favicon_url(url))
    doc = _load(args.file)
    add_link(doc, args.group, link)
    _write(args.file, doc)
    log.info("added %r -> %s [%s]", link.title, link.url, args.group)


def _cmd_rm(args: argparse.Namespace) -> None:
    doc = _load(args.file)
    remove_link(doc, args.url)
    _write(args.file, doc)
    log.info("removed %s", args.url)


def _cmd_ls(args: argparse.Namespace) -> None:
    for group, link in _all_links(_load(args.file)):
        log.info("%-16s %-24s %s", group.get("title", ""), link["title"], link["url"])


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--file", type=Path, default=DEFAULT_FILE, help="bookmarks yaml"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    add = sub.add_parser("add", help="add a bookmark")
    add.add_argument("url")
    add.add_argument("-g", "--group", default=DEFAULT_GROUP)
    add.add_argument("-t", "--title", help="default: page <title>, else hostname")
    add.add_argument("-i", "--icon", help="default: site favicon (si:/di:/sh:/URL ok)")
    add.set_defaults(func=_cmd_add)

    rm = sub.add_parser("rm", help="remove a bookmark by URL")
    rm.add_argument("url")
    rm.set_defaults(func=_cmd_rm)

    sub.add_parser("ls", help="list bookmarks").set_defaults(func=_cmd_ls)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    args = _parser().parse_args(argv)
    try:
        args.func(args)
    except BookmarkError as exc:
        log.error("error: %s", exc)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
