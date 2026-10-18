#!/usr/bin/env bash
# Native Linux tool install (the Brewfile equivalent). WSL2 uses the wsl-tools
# task in Makefile.toml instead.
#
# Detects dnf, apt, or pacman, installs what the distro packages, then fills
# gaps (tools missing or too old in the repos) from cargo, go, or upstream
# install scripts. Safe to re-run: every step skips what is already present.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
HOSTNAME_TARGET="mitch-linux"
NERD_FONTS=("JetBrainsMono" "Hack")
NERD_FONTS_VERSION="v3.4.0"

log() { printf '\n--- %s ---\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }

detect_pm() {
  if has dnf; then echo dnf
  elif has apt-get; then echo apt
  elif has pacman; then echo pacman
  else
    echo "No supported package manager (dnf, apt, pacman) found" >&2
    exit 1
  fi
}

# ---------- distro packages ----------

install_dnf() {
  sudo dnf install -y \
    zsh fzf ripgrep fd-find bat neovim tmux mosh fastfetch gh git curl unzip \
    gcc gcc-c++ make cmake pkgconf-pkg-config openssl-devel \
    golang lua nodejs \
    wl-clipboard xdg-utils
  # Ghostty is not in the Fedora repos yet
  if ! has ghostty; then
    sudo dnf copr enable -y scottames/ghostty
    sudo dnf install -y ghostty
  fi
}

install_apt() {
  sudo apt-get update
  sudo apt-get install -y \
    zsh fzf ripgrep fd-find bat neovim tmux mosh fastfetch gh git curl unzip \
    build-essential cmake pkg-config libssl-dev \
    golang-go lua5.1 nodejs \
    wl-clipboard xdg-utils
  # Debian renames fd and bat to avoid clashes; expose the usual names
  mkdir -p "$HOME/.local/bin"
  has fd || ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  has bat || ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  if ! has ghostty; then
    # Community .deb builds: https://github.com/mkasberg/ghostty-ubuntu
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
  fi
}

install_pacman() {
  sudo pacman -Syu --needed --noconfirm \
    zsh fzf ripgrep fd bat eza neovim tmux mosh fastfetch github-cli git curl unzip \
    base-devel cmake openssl \
    go lua51 nodejs \
    starship lazygit bottom ghostty uv \
    wl-clipboard xdg-utils
}

# ---------- gap fillers (skip when the distro already provided it) ----------

install_fallbacks() {
  log "Filling gaps from cargo / go / upstream installers"
  has eza || cargo install eza
  has btm || cargo install bottom
  has starship || curl -sS https://starship.rs/install.sh | sh -s -- -y
  has uv || curl -LsSf https://astral.sh/uv/install.sh | sh
  has bun || curl -fsSL https://bun.sh/install | bash
  has lazygit || go install github.com/jesseduffield/lazygit@latest
  has lazydocker || go install github.com/jesseduffield/lazydocker@latest
  has gopass || go install github.com/gopasspw/gopass@latest
}

install_fonts() {
  local font_dir="$HOME/.local/share/fonts"
  mkdir -p "$font_dir"
  for font in "${NERD_FONTS[@]}"; do
    if ls "$font_dir/${font}"*NerdFont* >/dev/null 2>&1; then
      continue
    fi
    log "Installing $font Nerd Font"
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/$font.zip" \
      "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/${font}.zip"
    unzip -oq "$tmp/$font.zip" -d "$font_dir"
    rm -rf "$tmp"
  done
  fc-cache -f "$font_dir"
}

# ---------- shell + machine setup ----------

install_zinit() {
  log "Installing zinit (plugins load from .zshrc)"
  git clone https://github.com/zdharma-continuum/zinit.git \
    "$HOME/.local/share/zinit/zinit.git" 2>/dev/null || true
}

install_uv_tools() {
  log "Installing Python CLI tools via uv"
  [[ -f "$DOTFILES/uv-tools.txt" ]] || return 0
  local uv_bin="${HOME}/.local/bin/uv"
  has uv && uv_bin="$(command -v uv)"
  while read -r package; do
    [[ -n "$package" ]] && { "$uv_bin" tool install "$package" 2>/dev/null || echo "Skipping $package"; }
  done < "$DOTFILES/uv-tools.txt"
}

setup_shell() {
  log "Creating ZDOTDIR bootstrap"
  echo 'export ZDOTDIR=$HOME/.config/zsh' > "$HOME/.zshenv"

  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    log "Setting zsh as login shell"
    chsh -s "$zsh_path"
  fi
}

setup_hostname() {
  if [[ "$(hostname)" != "$HOSTNAME_TARGET" ]]; then
    log "Setting hostname to $HOSTNAME_TARGET for dotter"
    sudo hostnamectl set-hostname "$HOSTNAME_TARGET"
  fi
}

main() {
  local pm
  pm="$(detect_pm)"
  log "Installing distro packages via $pm"
  "install_$pm"

  # cargo/go installs land here; make them visible for the rest of the run
  export PATH="$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/.bun/bin:$PATH"

  install_fallbacks
  install_fonts
  install_zinit
  install_uv_tools
  setup_shell
  setup_hostname

  log "Moshi remote-coding"
  echo "finish Moshi setup with: bunx moshi-hooks token <YOUR_TOKEN>"
}

main "$@"
