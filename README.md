# Dotfiles

Feel free to take what you want, but I would advise against blindly installing without reviewing.

> These dotfiles are unix-first, adapted to work on Windows via WSL2.

---

## Architecture

This repo is designed around a **unix-first** philosophy. The core dev environment (zsh, neovim, CLI tools) targets unix, and Windows gets there via WSL2.

```
macOS:    native apps (Ghostty, AeroSpace) --> unix backend (zsh, neovim, zellij)
Windows:  native apps (WezTerm, AHK)       --> WSL2 --> unix backend (zsh, neovim, zellij)
```

Both platforms converge on the same `common/` configs for the shell and dev tools. The difference is only in the GUI layer above.

### What lives where

| Directory  | Purpose                          | Used by           |
|------------|----------------------------------|--------------------|
| `common/`  | Base layer -- shell, dev tools, editors | All platforms |
| `macos/`   | macOS-only GUI apps              | macOS only         |
| `windows/` | Windows-only GUI apps            | Windows host only  |

---

## Requirements

1. **Unix-First** -- configs are written for unix. Windows uses WSL2 to run them.
2. **Performance-First** -- preference for modern, Rust-based tools (eza, bat, ripgrep, fd).
3. **Easy Installation** -- `dotter` for symlinks, `cargo-make` for setup automation.

---

## How to Install

### Prerequisites

Install Rust and cargo-make:

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Verify
rustc --version && cargo --version

# Install cargo-make
cargo install cargo-make
```

### Clone and init

```bash
git clone git@github.com:msetsma/.dotfiles.git
cd .dotfiles
cargo make init
```

### Windows (two-step setup)

On Windows, you run init twice -- once on the Windows host for native apps, and once inside WSL2 for the dev environment:

```bash
# 1. Windows host (PowerShell/cmd) -- installs Scoop packages, WezTerm, AHK
cargo make init

# 2. Inside WSL2 -- installs zsh, oh-my-zsh, CLI tools, symlinks common/ configs
cargo make init
```

The repo lives on the Windows filesystem and is accessed from WSL2 via `/mnt/c/Users/<you>/.dotfiles`.

### View available commands

```bash
cargo make help    # Quick reference
cargo make info    # All commands
```

---

## Common Tasks

### Setup & Updates

```bash
cargo make init            # Complete environment setup
cargo make update          # Update all tools and packages
cargo make check-outdated  # Check for available updates
cargo make doctor          # System health check
```

### Package Management (cross-platform)

```bash
cargo make pkg-export      # Export packages
cargo make pkg-import      # Import packages
cargo make pkg-cleanup     # Cleanup old versions
cargo make pkg-doctor      # Check for issues
```

Platform-specific: `brew-*` (macOS), `scoop-*` (Windows), `apt` (WSL2/Linux).

### Dotfile Deployment

```bash
cargo make deploy          # Deploy dotfiles via dotter
cargo make dotfiles-check  # Validate without deploying
```

### Git Backup

```bash
cargo make backup                        # Quick backup (auto-commit message)
cargo make deploy-and-backup             # Deploy + backup (all-in-one)
cargo make backup-with-message -- "msg"  # Custom message
```

### Python/pipx

```bash
cargo make pipx-list       # List installed packages
cargo make pipx-export     # Export to file
cargo make pipx-install    # Install from file
```

### Utilities

```bash
cargo make clean           # Cleanup caches
cargo make info            # Show all available commands
```

---

## Tools

> Common tools are cross-platform. Installation methods differ by OS.

### Common (all platforms)

[Neovim](https://neovim.io/) | [Zsh](https://www.zsh.org/) + [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) | [Zellij](https://github.com/zellij-org/zellij) | [Mise](https://github.com/jdx/mise) | [Dotter](https://github.com/SuperCuber/dotter) | [Cargo-Make](https://github.com/sagiegurari/cargo-make) | [Starship](https://github.com/starship/starship) | [fzf](https://github.com/junegunn/fzf) | [eza](https://github.com/eza-community/eza) | [bat](https://github.com/sharkdp/bat) | [ripgrep](https://github.com/BurntSushi/ripgrep) | [fd](https://github.com/sharkdp/fd) | [yazi](https://github.com/sxyazi/yazi) | [lazygit](https://github.com/jesseduffield/lazygit) | [Bottom](https://github.com/ClementTsang/bottom) | [Ruff](https://github.com/astral-sh/ruff) | [Vivid](https://github.com/sharkdp/vivid) | [FiraCode](https://github.com/tonsky/FiraCode)

### macOS-only (GUI layer)

[Ghostty](https://ghostty.org/) | [AeroSpace](https://github.com/nikitabobko/AeroSpace) | [borders](https://github.com/FelixKratz/JankyBorders)

### Windows-only (GUI layer)

[WezTerm](https://github.com/wez/wezterm) | [AutoHotkey](https://github.com/AutoHotkey/AutoHotkey) | [Scoop](https://scoop.sh/)

---

## Platform Detection

Shell configs use `common/zsh/platform.zsh` to detect the runtime environment:

- `IS_MAC` -- macOS (Darwin)
- `IS_WSL` -- WSL2 (Linux with Microsoft kernel)
- `IS_LINUX` -- generic Linux

This drives platform-specific behavior like clipboard (`pbcopy` vs `clip.exe`), URL opening (`open` vs `wslview`), and credential storage (Keychain vs env files).

---

## Gotchas

### Compiler Suite

- **macOS**: Clang (via Xcode command line tools)
- **Windows**: MSVC (Visual Studio Build Tools, "Desktop development with C++" workload)
- **WSL2/Linux**: GCC (`sudo apt install build-essential`)

### WSL2 Line Endings

The repo uses `.gitattributes` to enforce LF line endings for shell scripts. This prevents issues when the repo lives on the Windows filesystem and is accessed from WSL2 via `/mnt/c`.

### WSL2 Hostname

Dotter uses hostname-based machine configs (`.dotter/<hostname>.toml`). If your WSL2 hostname matches your Windows hostname, set a distinct one in `/etc/wsl.conf`:

```ini
[network]
hostname = mitch-wsl
```
