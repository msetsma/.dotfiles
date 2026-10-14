"""Run: uv run --with pytest --with ruamel.yaml pytest windows/glance"""

from pathlib import Path

import pytest

import glance_add as ga

SAMPLE = """\
# keep me
- type: bookmarks
  groups:
    - title: Dev
      links:
        - title: GitHub
          url: https://github.com/
          icon: si:github
"""


@pytest.fixture
def bookmarks(tmp_path: Path) -> Path:
    path = tmp_path / "bookmarks.yml"
    path.write_text(SAMPLE, encoding="utf-8")
    return path


def test_favicon_url_uses_host() -> None:
    assert ga.favicon_url("https://dynasty-daddy.com/rankings") == (
        "https://www.google.com/s2/favicons?domain=dynasty-daddy.com&sz=64"
    )


@pytest.mark.parametrize("url", ["ftp://x.com", "github.com", "https://"])
def test_validate_url_rejects(url: str) -> None:
    with pytest.raises(ga.BookmarkError):
        ga.validate_url(url)


def test_parse_title_collapses_whitespace() -> None:
    assert (
        ga.parse_title("<html><title>\n  Dynasty   Daddy </title>") == "Dynasty Daddy"
    )
    assert ga.parse_title("<html></html>") is None


def test_add_to_new_group_preserves_comments(bookmarks: Path) -> None:
    rc = ga.main(
        ["--file", str(bookmarks), "add", "https://x.com/", "-g", "Social", "-t", "X"]
    )
    text = bookmarks.read_text(encoding="utf-8")
    assert rc == 0
    assert text.startswith("# keep me")
    assert "\n- type: bookmarks\n  groups:\n    - title: Dev" in text
    assert "title: Social" in text and "domain=x.com" in text
    assert b"\r\n" not in bookmarks.read_bytes()


def test_add_duplicate_fails(bookmarks: Path) -> None:
    assert (
        ga.main(["--file", str(bookmarks), "add", "https://github.com/", "-t", "G"])
        == 1
    )


def test_add_falls_back_to_hostname(
    bookmarks: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(ga, "fetch_title", lambda url: None)
    ga.main(["--file", str(bookmarks), "add", "https://example.org/a", "-g", "Dev"])
    assert "title: example.org" in bookmarks.read_text(encoding="utf-8")


def test_rm_drops_empty_group(bookmarks: Path) -> None:
    assert ga.main(["--file", str(bookmarks), "rm", "https://github.com/"]) == 0
    assert "Dev" not in bookmarks.read_text(encoding="utf-8")
    assert ga.main(["--file", str(bookmarks), "rm", "https://github.com/"]) == 1


def test_poke_glance_relinks_only_matching_symlink(
    bookmarks: Path, tmp_path: Path
) -> None:
    deployed = tmp_path / "deployed.yml"
    try:
        deployed.symlink_to(bookmarks)
    except OSError:
        pytest.skip("symlinks not permitted")
    assert ga.poke_glance(bookmarks, deployed) is True
    assert deployed.is_symlink() and deployed.resolve() == bookmarks.resolve()
    assert ga.poke_glance(tmp_path / "other.yml", deployed) is False
    assert ga.poke_glance(bookmarks, tmp_path / "missing.yml") is False
