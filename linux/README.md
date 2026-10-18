# Linux (native)

GUI layer for a native Linux desktop. Target machine: Surface Pro 7 (`mitch-linux`) running GNOME with the [linux-surface](https://github.com/linux-surface/linux-surface) kernel. WSL2 config lives in `windows/wsl/` instead.

## Fresh machine

```bash
# git + a compiler first (Fedora shown; Ubuntu: sudo apt install git curl build-essential)
sudo dnf install -y git curl gcc

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"
cargo install cargo-make

git clone git@github.com:msetsma/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
cargo make linux-surface   # optional; reboot after
cargo make init
cargo make linux-desktop
```

Log out and back in so zsh (login shell), the hostname, and GNOME workspaces take effect.

## What maps to what

| macOS | Linux | Notes |
|---|---|---|
| `Brewfile` | `install-tools.sh` | dnf / apt / pacman, gaps filled from cargo, go, and upstream installers |
| Ghostty | Ghostty | shared `common/ghostty/config`; `ghostty/platform` holds the Linux overrides |
| AeroSpace | GNOME + `gnome/settings.sh` | `alt+1..7` workspace, `alt+shift+1..7` move window, `alt+f` maximize, `super+Return` Ghostty |
| Keychain (`security`) | `~/.config/databricks/.env-<env>` | already handled by `_use_databricks` |
| `pbcopy` / `open` | `wl-copy` / `xdg-open` | already handled by `common/zsh/adapters.zsh` |
| `~/Library/Application Support/bottom` | `~/.config/bottom` | via the shared `linux` dotter package |

## Not ported (yet)

- **AeroSpace tiling and app-focus binds** (`ctrl+alt+cmd+<key>`): GNOME has no tiling. Hyprland would fit these, but touch and pen on the Surface are much better on GNOME.
- **Ghostty quick terminal**: needs `wlr-layer-shell`, which GNOME does not implement.
- **Glance**: config lives in `macos/glance/` and `windows/glance/`; add a `linux/glance/` copy plus a systemd user unit if wanted.
- **Handy**: grab the `.rpm`/`.deb` from its GitHub releases.
- **LaunchAgents** (`entra` cache refresh): would become a systemd user timer.
- **Firefox Betterfox**: `windows/firefox/user.js` works here too; map it in `.dotter/mitch-linux.toml` once the profile dir exists (`~/.mozilla/firefox/<id>.default-release/user.js`).
