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

# ─────────────────────────────────────────────────────────────
# 3. Secrets & aliases
# ─────────────────────────────────────────────────────────────
source "$ZDOTDIR/.secrets.zsh"
source "$ZDOTDIR/aliases.zsh"

# ─────────────────────────────────────────────────────────────
# 4. Completions (before compinit)
# ─────────────────────────────────────────────────────────────
# Package manager site-functions (Homebrew/Linuxbrew)
[[ -n "$PKG_PREFIX" ]] && fpath+=("$PKG_PREFIX/share/zsh/site-functions")

# uv/uvx completions, cached
_uv_comp_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$_uv_comp_dir"
[[ ! -f "$_uv_comp_dir/_uv" ]]  && uv  generate-shell-completion zsh > "$_uv_comp_dir/_uv"  2>/dev/null
[[ ! -f "$_uv_comp_dir/_uvx" ]] && uvx --generate-shell-completion zsh > "$_uv_comp_dir/_uvx" 2>/dev/null

# zsh-completions plugin needs to be on fpath before compinit
fpath=(
  "$ZDOTDIR/functions"
  "$ZDOTDIR/plugins/zsh-completions/src"
  "$_uv_comp_dir"
  $fpath
)

# Cached compinit (full security check once per day)
autoload -Uz compinit
if [[ -n "$ZDOTDIR/.zcompdump"(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Autoload custom functions
for func_file in "$ZDOTDIR/functions"/*(N); do
  autoload -Uz "${func_file:t}"
done

# ─────────────────────────────────────────────────────────────
# 5. Plugins (order matters: syntax-highlighting LAST)
# ─────────────────────────────────────────────────────────────
# source "$ZDOTDIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
# source "$ZDOTDIR/plugins/fzf-tab/fzf-tab.plugin.zsh"
# source "$ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

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

# Completion behavior
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk
