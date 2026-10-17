# AGENTS.md

Guidance for coding agents working in this repo. See [README.md](README.md) for layout and setup.

## Git workflow

- Personal, single-user repo: commit and push **straight to `main`**. No feature branches or PRs unless asked.
- Only commit or push when the user asks.
- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, with an optional scope (`feat(glance): ...`).
- No em or en dashes in prose, comments, or commit messages.

## Layout

- `common/`: cross-platform configs (zsh, Neovim, tmux, CLI tools). Unix-first; Windows runs them through WSL2.
- `macos/`, `windows/`: platform GUI layer only.
- `.dotter/`: dotter deploy config (`global.toml`, per-host `<hostname>.toml`). Add new files here to deploy them.
- `Makefile.toml`: cargo-make tasks (`cargo make help`).

## Gotchas

- **Line endings:** shell scripts must stay LF (`.gitattributes`); the repo is shared with WSL2 via `/mnt/c`.
- **dotter templating:** files containing `{{ }}` (e.g. Glance Go templates) must be deployed with `type = "symbolic"` or dotter's handlebars pass mangles them.
- **Glance (Windows):** `~/.glance/glance.yml` is a symlink into this repo, and Glance's file watcher misses edits made through it. After editing, validate and restart:

  ```sh
  ~/.glance/glance.exe --config ~/.glance/glance.yml config:validate
  ```

  then restart `glance.exe` with the same `--config` argument. Widgets load async from `/api/pages/home/content/`, so check that endpoint (not `/`) to verify a change.
- **Glance bookmarks:** manage with `uv run windows/glance/glance_add.py add|rm|ls`; groups are kept alphabetical.

## Tests

```sh
uv run --with pytest --with ruamel.yaml pytest windows/glance
```
