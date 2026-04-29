# CLAUDE.md - AI Assistant Guide

This document helps AI assistants (like Claude) understand and work effectively with this dotfiles repository.

## Architecture

This repo is **unix-first**. The core dev environment (zsh, neovim, CLI tools) targets unix, and Windows gets there via WSL2. Both platforms converge on the same `common/` configs.

```
macOS:    native apps (Ghostty, AeroSpace) --> unix backend (zsh, neovim, tmux)
Windows:  native apps (WezTerm, AHK)       --> WSL2 --> unix backend (zsh, neovim, tmux)
```

**Owner**: msetsma
**Primary Platform**: macOS
**Secondary Platform**: Windows (native GUI + WSL2 for dev)
**Management Tools**: dotter, cargo-make, mise

### Directory model

| Directory  | Purpose | Used by | Dotter package |
|------------|---------|---------|----------------|
| `common/`  | Base layer -- shell, editors, dev tools, linters | All platforms | `common` |
| `macos/`   | macOS-only GUI apps (aerospace, ghostty, borders) | macOS only | `mac` |
| `windows/` | Windows-only GUI apps (wezterm, ahk, komorebi) | Windows host only | `windows` |

### Platform layers

| Layer | macOS | Windows |
|-------|-------|---------|
| GUI apps | Ghostty, AeroSpace, borders | WezTerm, AHK, (komorebi undecided) |
| Terminal | Ghostty (native) | WezTerm -> WSL2 |
| Shell | zsh (oh-my-zsh) | zsh via WSL2 (oh-my-zsh) |
| Dev tools | neovim, tmux, fzf, eza, bat, rg | same, via WSL2 |
| Package mgr | Homebrew | Scoop (Windows host) + apt (WSL2) |

### Platform detection

`common/zsh/platform.zsh` sets `PLATFORM` and boolean flags used throughout shell configs:

- `IS_MAC` (1/0) -- macOS (Darwin)
- `IS_WSL` (1/0) -- WSL2 (detects via `/proc/version`)
- `IS_LINUX` (1/0) -- generic Linux

Platform-specific behavior gated by `(( IS_MAC ))` / `(( IS_WSL ))`:
- **Clipboard**: `pbcopy` (mac), `clip.exe` (WSL2), `xclip` (linux) -- abstracted as `_clip` function
- **URL open**: `open` (mac), `wslview` (WSL2), `xdg-open` (linux) -- aliased as `open`
- **Credentials**: macOS Keychain `security` CLI vs `~/.config/databricks/.env-{env}` files
- **PATH**: `/opt/homebrew/bin` (mac) vs standard linux paths + optional linuxbrew

## Repository Structure

``` text
.dotfiles/
├── common/             # Base layer (all platforms)
│   ├── bash/           # Bash config
│   ├── bottom/         # System monitor config
│   ├── cargo/          # Rust/Cargo configuration
│   ├── fastfetch/      # System info tool
│   ├── linters/        # ruff.toml, stylua.toml
│   ├── mise/           # Runtime version manager
│   ├── nvim/           # Neovim configuration (lazy.nvim)
│   ├── starship/       # Shell prompt
│   ├── tmux/           # Terminal multiplexer
│   └── zsh/            # Zsh config (active shell on both platforms)
│       ├── .zshrc      # Main config (sources platform.zsh first)
│       ├── .zshenv     # Environment vars
│       ├── platform.zsh # Platform detection (IS_MAC, IS_WSL, IS_LINUX)
│       ├── aliases.zsh  # Aliases with platform abstractions (_clip, open)
│       └── functions/   # Autoloaded functions
├── macos/              # macOS-only GUI apps
│   ├── aerospace/      # AeroSpace tiling window manager
│   ├── borders/        # Window border visual effects
│   └── ghostty/        # Terminal emulator
├── windows/            # Windows-native GUI apps (host side only)
│   ├── ahk/            # AutoHotkey scripts
│   ├── komorebi/       # Tiling window manager (undecided)
│   ├── nushell/        # Nushell config
│   ├── wezterm/        # Terminal emulator
│   └── whkdrc/         # Hotkey daemon config
├── .dotter/            # Dotter configuration
│   ├── global.toml     # Symlink mappings: [common], [mac], [windows], [linux]
│   ├── mitch-pc.toml   # Windows machine (packages: common + windows)
│   ├── APF1YN4YGV37.toml # macOS machine (packages: common + mac)
│   └── mitch-wsl.toml  # WSL2 machine (packages: common + linux)
├── Brewfile            # Homebrew packages (macOS)
├── Makefile.toml       # Cargo-make setup/install tasks
├── Makefile.utils.toml # Cargo-make utility tasks
├── .gitattributes      # Line ending enforcement (LF for shell, CRLF for Windows scripts)
└── README.md           # User-facing documentation
```

## Key Files

### Management & Configuration

- **[.dotter/global.toml](.dotter/global.toml)**: Symlink mappings. Sections: `[common.files]`, `[mac.files]`, `[windows.files]`, `[linux.files]`
- **[Makefile.toml](Makefile.toml)**: Setup/install tasks. Platform branching via `mac_alias`, `windows_alias`, `linux_alias`
- **[Makefile.utils.toml](Makefile.utils.toml)**: Daily utility tasks (pkg management, backup, doctor)

### Shell Configuration

- **[common/zsh/platform.zsh](common/zsh/platform.zsh)**: Platform detection -- sourced first by .zshrc
- **[common/zsh/.zshrc](common/zsh/.zshrc)**: Main zsh config (platform-gated PATH, brew, fzf, oh-my-zsh)
- **[common/zsh/aliases.zsh](common/zsh/aliases.zsh)**: Aliases with `_clip` clipboard abstraction and `open` alias
- **[common/zsh/functions/](common/zsh/functions/)**: Autoloaded functions (update, cmds, _use_databricks, etc.)

### Dotter Platform Mapping

Dotter selects config based on hostname -> machine toml -> packages list -> global.toml sections:

| Package | Symlinks from | Used on |
|---------|---------------|---------|
| `common` | `common/*` | All platforms |
| `mac` | `common/bottom` (macOS path) + `macos/*` | macOS |
| `linux` | `common/bottom` (linux path) | WSL2 |
| `windows` | `windows/*` | Windows host |

## Setup Workflow

### macOS

```bash
cargo make init  # Installs brew packages, oh-my-zsh, rust tools, symlinks
```

### Windows (two-step)

```bash
# 1. Windows host -- Scoop packages, native app configs
cargo make init

# 2. Inside WSL2 -- apt packages, zsh, oh-my-zsh, symlinks common/ configs
cargo make init
```

The repo is at `C:\Users\2015m\.dotfiles` and accessed from WSL2 via `/mnt/c/Users/2015m/.dotfiles`.

### Updates

```bash
cargo make update       # Update all tools
cargo make check-outdated # Check without applying
update                  # zsh function (brew/apt + rustup + cargo + mise)
```

## Development Environment

### Languages (via Mise)

- Python: latest
- Go: latest
- Lua: 5.1 (for Neovim)

### Neovim

- Plugin manager: lazy.nvim
- Structure: `nvim/lua/{core,plugins}/`
- Plugins: blink-cmp, telescope, neo-tree, gitsigns, treesitter, LSP, snacks

### Tools & Utilities

**File ops**: eza, bat, yazi, fzf, ripgrep, fd
**Git**: lazygit, fzf git checkout function
**System**: bottom, fastfetch
**Python**: ruff (linting/formatting)
**Terminal**: tmux (multiplexer), mosh (mobile-friendly SSH)

## User Preferences & Patterns

### Naming Conventions

- Functions: lowercase with underscores (`git_fzf_checkout`)
- Aliases: lowercase abbreviations (`gfc`, `lt`, `db`)
- Scripts: snake_case.sh

### Style Preferences

- **Unix-first**: write for unix, adapt for Windows via WSL2
- **Shell**: prefers functions over complex aliases
- **Tools**: performance-focused (Rust tools preferred)
- **Comments**: functional, not verbose
- **Files**: many small files > few large files

### Work Context

- **Cloud**: Azure (az CLI, Azure Functions)
- **Data**: Databricks (`db-prod`, `db-qa`, `db-dev`)
- **Languages**: Python (ruff), Go, Lua

## AI Assistant Guidelines

### When Making Changes

1. **Unix-first**: write shell configs for unix. Use `(( IS_MAC ))` / `(( IS_WSL ))` guards for platform-specific behavior
2. **Use dotter-aware paths**: changes must align with `.dotter/global.toml` mappings
3. **Three directories**: `common/` for the base layer, `macos/` for mac GUI apps, `windows/` for Windows GUI apps
4. **Test symlinks**: suggest `dotter -v` after config changes
5. **Platform branching in Makefile**: use `mac_alias`, `windows_alias`, `linux_alias`

### Adding a new tool config

1. Create directory under `common/`, `macos/`, or `windows/` as appropriate
2. Add entry to `.dotter/global.toml` under the correct `[*.files]` section
3. Add installation to `Makefile.toml` under relevant `install-*-tools` task (with platform aliases if needed)
4. Run `cargo make dotfiles` to symlink

### Modifying zsh config

- Edit source: `common/zsh/{.zshrc,aliases.zsh,platform.zsh,functions/}`
- Use `(( IS_MAC ))` / `(( IS_WSL ))` for platform-specific code
- Use `_clip` function (not `pbcopy` directly) for clipboard operations
- Use `open` alias (not `open` command directly) for URL/file opening
- Symlinked to: `~/.config/zsh/`
- Test with: `rld` (reload shell)

### Don't Assume

- Which platform user is currently on (check context or ask)
- That all tools are installed (user may be mid-setup)
- That `pbcopy`, `open`, or `security` are available (use platform abstractions)
- Windows configs are outdated (they're maintained for the host GUI layer)

## Troubleshooting

### Symlinks Not Working

```bash
cd ~/.dotfiles && dotter -v
```

Check `.dotter/global.toml` for correct paths and ensure hostname matches a `.dotter/<hostname>.toml` file.

### Tools Not Found After Install

PATH includes (platform-dependent):
- `/opt/homebrew/bin` (macOS Homebrew)
- `/home/linuxbrew/.linuxbrew/bin` (Linuxbrew, if installed)
- `~/.cargo/bin` (Rust tools)
- `~/.local/bin` (Local installs)

### WSL2 Line Endings

`.gitattributes` enforces LF for shell files. If scripts break with `\r` errors, run:

```bash
git add --renormalize .
```

### Cargo-Make Platform Detection

```bash
rustc -Vv | grep host    # Shows detected platform
cargo make --print-only <task-name>  # Debug task resolution
```

## External Resources

- **Dotter**: <https://github.com/SuperCuber/dotter>
- **Cargo-Make**: <https://github.com/sagiegurari/cargo-make>
- **AeroSpace**: <https://github.com/nikitabobko/AeroSpace>
- **Mise**: <https://github.com/jdx/mise>

---

**Last Updated**: 2026-03-01
**For**: AI assistants working with msetsma's dotfiles
