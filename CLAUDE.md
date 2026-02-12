# CLAUDE.md - AI Assistant Guide

This document helps AI assistants (like Claude) understand and work effectively with this dotfiles repository.

## Repository Overview

This is a cross-platform dotfiles repository managed by **dotter** (a dotfile symlink manager) with platform-specific configurations for macOS, Windows, and Linux. The repo emphasizes modern, performance-focused tools (many Rust-based) and uses **cargo-make** for automation.

**Owner**: msetsma
**Primary Platform**: macOS (currently active)
**Secondary Platform**: Windows (via Scoop)
**Management Tools**: dotter, cargo-make, mise

**Note**: Linux support discontinued - partial implementation remains in Makefile.toml but is not actively maintained

## Repository Structure

``` text
.dotfiles/
├── _osx/           # macOS-specific configs (zsh, bash scripts, borders)
├── _windows/       # Windows-specific configs (AHK, komorebi)
├── aerospace/      # AeroSpace window manager (macOS)
├── bottom/         # System monitor config
├── cargo/          # Rust/Cargo configuration
├── claude/         # Claude Code settings
├── code-tools/     # Linters/formatters (ruff, lua)
├── fastfetch/      # System info tool
├── ghostty/        # Terminal emulator config
├── mise/           # Runtime version manager
├── night-tab/      # Browser new tab page backup
├── nushell/        # Nushell config (Windows-focused)
├── nvim/           # Neovim configuration (lazy.nvim)
├── scripts/        # Helper scripts (bash, python)
├── sketchybar/     # macOS status bar (laptop/desktop variants)
├── starship/       # Shell prompt
├── television/     # Fuzzy finder
├── wezterm/        # Terminal emulator (Windows-focused)
├── yazi/           # File manager
├── .dotter/        # Dotter configuration
├── Makefile.toml   # Cargo-make automation
├── TODO.md         # Active todo list
└── README.md       # User-facing documentation
```

## Key Files

### Management & Configuration

- **[.dotter/global.toml](.dotter/global.toml)**: Controls which dotfiles get symlinked to which locations per platform
- **[Makefile.toml](Makefile.toml)**: Defines all setup, update, and maintenance tasks via cargo-make
- **[TODO.md](TODO.md)**: Current work items (kept minimal)

### Shell Configuration (macOS Active)

- **[_osx/zsh/.zshrc](_osx/zsh/.zshrc)**: Main zsh config (sources aliases/functions, configures fzf, oh-my-zsh)
- **[_osx/zsh/aliases.zsh](_osx/zsh/aliases.zsh)**: Shell aliases (eza for ls, git shortcuts, Azure/Databricks)
- **[_osx/zsh/functions.zsh](_osx/zsh/functions.zsh)**: Custom functions (rld, update, az-func-info)

### Window Management (macOS)

- **[aerospace/aerospace.toml](aerospace/aerospace.toml)**: AeroSpace tiling WM config with workspace rules
- **[_osx/borders/bordersrc](_osx/borders/bordersrc)**: Window border visual effects
- **[sketchybar/](sketchybar/)**: Status bar (has laptop/desktop variants)

### Terminal & Prompt

- **[ghostty/config](ghostty/config)**: Primary terminal (Catppuccin Mocha, quick-terminal with cmd+`)
- **[starship/starship.toml](starship/starship.toml)**: Shell prompt configuration

### Development Tools

- **[nvim/](nvim/)**: Neovim with lazy.nvim plugin manager
- **[mise/config.toml](mise/config.toml)**: Manages Python/Go/Lua versions
- **[code-tools/ruff/ruff.toml](code-tools/ruff/ruff.toml)**: Python linting/formatting

## Platform-Specific Details

### macOS (Primary)

**Package Manager**: Homebrew
**Shell**: zsh (with oh-my-zsh)
**Window Manager**: AeroSpace (tiling)
**Terminal**: Ghostty
**Tools**: borders, sketchybar, fzf, ripgrep, bat, eza, lazygit

**Key Locations**:

- Configs: `~/.config/` (via XDG_CONFIG_HOME)
- Dotfiles symlinked by dotter
- Zsh sources from `~/.config/zsh/`

### Windows (Secondary)

**Package Manager**: Scoop
**Shell**: Nushell
**Window Manager**: komorebi
**Terminal**: WezTerm
**Automation**: AutoHotkey

### Linux (Discontinued)

**Status**: No longer actively maintained
**Note**: Partial implementation remains in Makefile.toml but is not being developed further

## Important Workflows

### Initial Setup

```bash
# From repo root:
cargo make init
```

This runs:

1. `install-rust` - Adds clippy, rustfmt
2. `install-tools` - Platform-specific tools (brew/scoop/dnf5)
3. `install-coreutils` - Platform-specific coreutils
4. `install-rust-tools` - mise, dotter, cargo-update, vivid, eza, bottom, bat
5. `dotfiles` - Runs `dotter -v` to create symlinks

### Updates

```bash
# Update everything:
cargo make update

# Check for updates without applying:
cargo make check-outdated
```

Or use the zsh function:

```bash
update  # Defined in _osx/zsh/functions.zsh
```

### Dotfile Deployment

After editing configs:

```bash
dotter -v  # Verbose mode shows what gets symlinked
```

Dotter reads `.dotter/global.toml` to determine platform and target paths.

### Shell Reload

```bash
rld  # Defined in _osx/zsh/functions.zsh, runs: exec zsh
```

## Development Environment

### Languages Managed by Mise

Per [mise/config.toml](mise/config.toml):

- Python: latest
- Go: latest
- Lua: 5.1 (for Neovim)

### Neovim

- Plugin manager: lazy.nvim
- Structure: `nvim/lua/{core,plugins}/`
- Plugins: blink-cmp, telescope, neo-tree, gitsigns, treesitter, LSP, snacks, etc.

### Tools & Utilities

**File Operations**: eza, bat, yazi, fzf, ripgrep, fd
**Git**: lazygit, fzf git checkout function
**System**: bottom, fastfetch
**Python**: ruff (linting/formatting)
**Rust**: cargo with custom config in cargo/config.toml

## User Preferences & Patterns

### Naming Conventions

- Functions: lowercase with underscores (e.g., `git_fzf_checkout`)
- Aliases: lowercase abbreviations (e.g., `gfc`, `lt`, `db`)
- Scripts: snake_case.sh

### Directory Shortcuts

Common aliases in [_osx/zsh/aliases.zsh](_osx/zsh/aliases.zsh):

- `home` → `~`
- `dotfiles` → `~/.dotfiles`
- `dev` → `~/dev`
- `mlops` → `~/dev/mlops`

### Workspace Organization (AeroSpace)

Defined in [aerospace/aerospace.toml](aerospace/aerospace.toml):

- **Workspace 1**: Development (VSCode, Terminal)
- **Workspace 2**: Communication (Teams, Claude, Slack)
- **Workspace 3**: Documentation (Obsidian)
- **Workspace 4**: Monitoring/Tools
- **Workspace 5-6**: Overflow

### Work Context Clues

Based on aliases and functions:

- **Cloud**: Heavy Azure usage (az-func-info function, Azure CLI shortcuts)
- **Data**: Databricks alias (`db`)
- **Languages**: Python (ruff), Go, Lua
- **Tools**: Git, Docker implied by workflow

## Git Workflow

### Current State

Branch: `main`
Recent activity: Mac-focused updates, cleaning up unix configs

### Modified Files (Uncommitted)

Per git status:

- `.dotter/global.toml`
- `.gitignore`
- `TODO.md`
- `_osx/zsh/` configs
- `cargo/config.toml`
- `code-tools/ruff/ruff.toml`
- `ghostty/config`
- `starship/starship.toml`

### Untracked Additions

- `_osx/borders/`
- `aerospace/`
- `bottom/`
- `claude/`
- `scripts/`
- `sketchybar/`

### Deleted (Migration from _unix)

Old `_unix/zsh/` configs were removed in favor of `_osx/` specificity.

## AI Assistant Guidelines

### When Making Changes

1. **Check platform context**: Currently on macOS, but Windows/Linux configs exist
2. **Use dotter-aware paths**: Changes should align with `.dotter/global.toml` mappings
3. **Respect structure**: Follow existing file organization patterns
4. **Test symlinks**: Suggest running `dotter -v` after config changes
5. **Update both source and symlink**: If editing, work in the repo, not symlinked locations

### Common Tasks

**Adding a new tool config**:

1. Create directory in repo root (e.g., `newtool/`)
2. Add entry to `.dotter/global.toml` under appropriate platform
3. Add installation to `Makefile.toml` under relevant `install-*-tools` task
4. Run `cargo make dotfiles` to symlink

**Modifying zsh config**:

- Edit source: `_osx/zsh/{.zshrc,aliases.zsh,functions.zsh}`
- Symlinked to: `~/.config/zsh/`
- Test with: `rld` (reload shell)

**Adding cargo-make task**:

- Edit [Makefile.toml](Makefile.toml)
- Use platform aliases: `linux_alias`, `windows_alias`, `mac_alias`
- Add to `dependencies` array of relevant top-level task

### Don't Assume

- Which platform user is currently on (check context or ask)
- That all tools are installed (user may be mid-setup)
- Windows configs are outdated (they're intentionally maintained)
- Linux configs are active (Linux support is discontinued)

### Style Preferences

- **Shell**: Prefers functions over complex aliases
- **Tools**: Performance-focused (Rust tools preferred)
- **Comments**: Functional, not verbose
- **Documentation**: External (README.md) vs inline

## Troubleshooting Common Issues

### Symlinks Not Working

```bash
cd ~/.dotfiles
dotter -v  # Verbose output shows what's happening
```

Check `.dotter/global.toml` for correct paths.

### Tools Not Found After Install

Ensure PATH includes:

- `/opt/homebrew/bin` (Homebrew)
- `~/.cargo/bin` (Rust tools)
- `~/.local/bin` (Local installs)

Check [_osx/zsh/.zshrc](_osx/zsh/.zshrc) for PATH configuration.

### Cargo-Make Task Fails

```bash
# Verify platform detection:
rustc -Vv | grep host

# Run specific task:
cargo make <task-name>

# Debug with:
cargo make --print-only <task-name>
```

### Neovim Plugin Issues

```bash
nvim  # Open Neovim
:Lazy sync  # Sync plugins with lazy.nvim
```

## Quick Reference

### Essential Commands

```bash
# Setup
cargo make init

# Update everything
cargo make update
# or
update

# Deploy dotfiles
dotter -v

# Reload shell
rld

# Git checkout with fzf
gfc

# Azure function app info
az-func-info

# Tree view with eza
lt2  # 2 levels deep
```

### File Navigation

```bash
dotfiles  # cd ~/.dotfiles
dev       # cd ~/dev
mlops     # cd ~/dev/mlops
```

### Key Bindings (AeroSpace)

- `alt-d`: Development workspace
- `alt-c`: Communication workspace
- `alt-h/j/k/l`: Focus windows (vim-style)
- `alt-shift-h/j/k/l`: Move windows
- `cmd+\``: Quick terminal (Ghostty)

## External Resources

- **Dotter**: <https://github.com/SuperCuber/dotter>
- **Cargo-Make**: <https://github.com/sagiegurari/cargo-make>
- **AeroSpace**: <https://github.com/nikitabobko/AeroSpace>
- **Mise**: <https://github.com/jdx/mise>

---

**Last Updated**: 2025-10-11
**For**: AI assistants working with msetsma's dotfiles
**Maintained**: Manually when significant changes occur
