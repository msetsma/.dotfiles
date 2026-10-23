# AGENTS.md

Guidance for coding agents working in this repo. See [README.md](README.md) for layout and setup.

## Git workflow

- Personal, single-user repo: commit and push **straight to `main`**. No feature branches or PRs unless asked.
- Only commit or push when the user asks.
- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, with an optional scope (`feat(glance): ...`).
- No em or en dashes in prose, comments, or commit messages.

## Layout

- `common/`: cross-platform configs (zsh, Neovim, tmux, CLI tools). Unix-first; Windows runs them through WSL2.
- `macos/`, `linux/`, `windows/`: platform GUI layer only. `linux/` is native Linux (GNOME, Surface Pro 7); WSL2 bits stay in `windows/wsl/`.
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

- **Linux vs WSL2:** cargo-make reports both as `linux`. Tasks split with `condition_script` on `/proc/version`; dotter packages are `linux` (shared) plus `linux-desktop` (native only).
- **Ghostty:** `common/ghostty/config` is the shared base; it includes `platform` from `macos/ghostty/` or `linux/ghostty/`.
- **Nushell (native Windows):** `windows/nushell/` deploys to `~/.config/nushell` (via `XDG_CONFIG_HOME`). Commands live in `autoload/*.nu`, sourced alphabetically after `config.nu`. `env.nu` caches starship/zoxide/carapace/vivid init into `%APPDATA%\nushell\vendor\autoload`; run `rld --regen` after upgrading those tools. Don't cache `mise activate nu` (it bakes in PATH; shims cover mise).
- **SSH and links (Windows):** sshd sessions run with RedirectionGuard and won't follow symlinks or junctions created unelevated ("untrusted mount point"), which breaks nushell config and scoop `current` paths over Moshi. Run `windows/ssh/trust-links.ps1` after `dotter deploy` adds links or `scoop update`.
- **Nushell checks:** `nu -c` skips autoloads, so test with `nu -e '<cmds>; exit'`. Git for Windows' `usr\bin` is on PATH, so a removed nu builtin (e.g. `fmt`) silently falls through to a coreutils binary.

## Tests

```sh
uv run --with pytest --with ruamel.yaml pytest windows/glance
```
