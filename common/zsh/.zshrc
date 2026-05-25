# ─────────────────────────────────────────────────────────────
# 1. Environment & platform detection
# ─────────────────────────────────────────────────────────────
source "$ZDOTDIR/.zshenv"
source "$ZDOTDIR/platform.zsh"

# ─────────────────────────────────────────────────────────────
# 2. PATH (must come before anything that calls binaries)
# ─────────────────────────────────────────────────────────────

# Only set PATH once
if [ -z "$PATH_SET" ]; then
  export GOPATH="$HOME/go"

  path_dirs=(
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "/usr/local/go/bin"
    "$GOPATH/bin"
  )

  [[ -n "$PKG_PREFIX" ]] && path_dirs=("$PKG_PREFIX/bin" "${path_dirs[@]}")
  (( IS_MAC )) && path_dirs=("/usr/local/bin" "${path_dirs[@]}")  # Intel fallback

  export PATH="$(IFS=:; echo "${path_dirs[*]}"):$PATH"
  export PATH_SET=1
fi

# Auto-attach interactive shells to tmux. Set TMUX_AUTO_START=0 to bypass.
if [[ -o interactive \
  && -z "${TMUX:-}" \
  && -z "${TMUX_AUTO_STARTED:-}" \
  && "${TMUX_AUTO_START:-1}" != "0" \
  && "${TERM:-}" != "dumb" ]] && (( $+commands[tmux] )); then
  export TMUX_AUTO_STARTED=1
  exec tmux new-session -A -s "${TMUX_AUTO_SESSION:-main}"
fi

# ─────────────────────────────────────────────────────────────
# 3. Secrets & aliases
# ─────────────────────────────────────────────────────────────
source "$ZDOTDIR/.secrets.zsh"
source "$ZDOTDIR/aliases.zsh"

# ─────────────────────────────────────────────────────────────
# 4. Zinit
# ─────────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
  print -P "%F{33}Installing zinit plugin manager...%f"
  command mkdir -p "${ZINIT_HOME:h}" && command chmod g-rwX "${ZINIT_HOME:h}"
  command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" && \
    print -P "%F{34}zinit installation successful.%f%b" || \
    print -P "%F{160}zinit clone failed.%f%b"
fi

source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load important annexes without Turbo mode.
zinit light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust

# zsh-completions must be available before compinit builds the completion cache.
zinit light zsh-users/zsh-completions

# ─────────────────────────────────────────────────────────────
# 5. Completions
# ─────────────────────────────────────────────────────────────
# Package manager site-functions (Homebrew/Linuxbrew)
[[ -n "$PKG_PREFIX" ]] && fpath+=("$PKG_PREFIX/share/zsh/site-functions")

# uv/uvx completions, cached
_uv_comp_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$_uv_comp_dir"
(( $+commands[uv] ))  && [[ ! -s "$_uv_comp_dir/_uv" ]]  && uv  generate-shell-completion zsh > "$_uv_comp_dir/_uv"  2>/dev/null
(( $+commands[uvx] )) && [[ ! -s "$_uv_comp_dir/_uvx" ]] && uvx --generate-shell-completion zsh > "$_uv_comp_dir/_uvx" 2>/dev/null

fpath=(
  "$ZDOTDIR/functions"
  "$_uv_comp_dir"
  $fpath
)

# Completion behavior
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Cached compinit (full security check once per day)
autoload -Uz compinit
if [[ -n "$ZDOTDIR/.zcompdump"(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
zinit cdreplay -q

# Autoload custom functions
for func_file in "$ZDOTDIR/functions"/*(N); do
  autoload -Uz "${func_file:t}"
done

# ─────────────────────────────────────────────────────────────
# 6. fzf
# ─────────────────────────────────────────────────────────────
[ -f "$HOME/.fzf.zsh" ] && source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# ─────────────────────────────────────────────────────────────
# 7. Prompt & runtime managers
# ─────────────────────────────────────────────────────────────
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[mise] ))     && eval "$(mise activate zsh)"

# ─────────────────────────────────────────────────────────────
# 8. Sensible zsh defaults (previously provided by OMZ)
# ─────────────────────────────────────────────────────────────
# History
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_VERIFY EXTENDED_HISTORY

# Directory navigation
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# ─────────────────────────────────────────────────────────────
# 9. Interactive plugins (syntax highlighting must stay last)
# ─────────────────────────────────────────────────────────────
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
