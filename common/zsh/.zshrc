# ─────────────────────────────────────────────────────────────
# 1. Environment & platform detection
# ─────────────────────────────────────────────────────────────
_zsh_source_dir="${${(%):-%x}:A:h}"
source "$_zsh_source_dir/platform.zsh"

typeset -gU path PATH fpath

# ─────────────────────────────────────────────────────────────
# 2. PATH (must come before anything that calls binaries)
# ─────────────────────────────────────────────────────────────
export GOPATH="$HOME/go"

path_dirs=(
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  "/usr/local/go/bin"
  "$GOPATH/bin"
)

[[ -n "$PKG_PREFIX" ]] && path_dirs=("$PKG_PREFIX/bin" "${path_dirs[@]}")
(( IS_MAC )) && path_dirs=("/usr/local/bin" "${path_dirs[@]}")  # Intel fallback

path=("${path_dirs[@]}" "${path[@]}")
export PATH

# ─────────────────────────────────────────────────────────────
# 3. Terminal integrations
# ─────────────────────────────────────────────────────────────
source "$_zsh_source_dir/integrations/tmux/init.zsh"

# ─────────────────────────────────────────────────────────────
# 4. Secrets & aliases
# ─────────────────────────────────────────────────────────────
[[ -r "$ZDOTDIR/.secrets.zsh" ]] && source "$ZDOTDIR/.secrets.zsh"
source "$_zsh_source_dir/adapters.zsh"
source "$_zsh_source_dir/aliases.zsh"

# ─────────────────────────────────────────────────────────────
# 5. Zinit
# ─────────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
_zinit_available=0
if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
  _zinit_available=1
  autoload -Uz _zinit
  (( ${+_comps} )) && _comps[zinit]=_zinit

  # Zinit annexes extend install behavior for plugins that need download/patch/build helpers.
  zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

  # zsh-completions must be available before compinit builds the completion cache.
  zinit light zsh-users/zsh-completions # Extra completion definitions.
else
  print -u2 -P "%F{220}zinit not found at $ZINIT_HOME; skipping zinit plugins. Install zinit manually to enable them.%f"
fi

# ─────────────────────────────────────────────────────────────
# 6. Function & completion paths
# ─────────────────────────────────────────────────────────────
# Package manager completion definitions.
[[ -n "$PKG_PREFIX" ]] && fpath+=("$PKG_PREFIX/share/zsh/site-functions")

# Generated uv/uvx completion definitions.
_uv_comp_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$_uv_comp_dir"
(( $+commands[uv] ))  && [[ ! -s "$_uv_comp_dir/_uv" ]]  && uv  generate-shell-completion zsh > "$_uv_comp_dir/_uv"  2>/dev/null
(( $+commands[uvx] )) && [[ ! -s "$_uv_comp_dir/_uvx" ]] && uvx --generate-shell-completion zsh > "$_uv_comp_dir/_uvx" 2>/dev/null

# Custom function directories.
# public = commands to run directly
# private = helpers
# widgets = ZLE keybinding handlers
_zsh_function_dirs=(
  "$_zsh_source_dir/functions/public"
  "$_zsh_source_dir/functions/private"
  "$_zsh_source_dir/functions/widgets"
)

# zsh searches fpath for autoloadable functions and completion definitions.
fpath=(
  "$_zsh_source_dir/functions/completions"
  $_zsh_function_dirs
  "$_uv_comp_dir"
  $fpath
)

# ─────────────────────────────────────────────────────────────
# 7. Completion behavior
# ─────────────────────────────────────────────────────────────
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Cached compinit; run the full security check once per day.
# WSL: /mnt/c (DrvFs) reports every dir as world-writable, so skip the check.
autoload -Uz compinit
if [[ -n "$ZDOTDIR/.zcompdump"(#qN.mh+24) ]]; then
  if [[ -n "$WSL_DISTRO_NAME" ]]; then compinit -u; else compinit; fi
else
  compinit -C
fi
(( _zinit_available )) && zinit cdreplay -q

# ─────────────────────────────────────────────────────────────
# 8. Custom function autoloads & keybindings
# ─────────────────────────────────────────────────────────────
for func_dir in "${_zsh_function_dirs[@]}"; do
  for func_file in "$func_dir"/*(N-.); do
    autoload -Uz "${func_file:t}"
  done
done

[[ -o interactive && -t 0 ]] && source "$_zsh_source_dir/keybindings.zsh"

# ─────────────────────────────────────────────────────────────
# 9. fzf
# ─────────────────────────────────────────────────────────────
# `fzf --zsh` needs fzf >= 0.48 (distro packages often ship older).
autoload -Uz is-at-least
if [[ -o interactive && -t 0 ]] && (( $+commands[fzf] )) \
  && is-at-least 0.48.0 ${${(s: :)$(fzf --version)}[1]}; then
  source <(fzf --zsh)
fi
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# ─────────────────────────────────────────────────────────────
# 10. Prompt & runtime managers
# ─────────────────────────────────────────────────────────────
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[mise] ))     && eval "$(mise activate zsh)"

# ─────────────────────────────────────────────────────────────
# 11. Sensible zsh defaults (previously provided by OMZ)
# ─────────────────────────────────────────────────────────────
# History
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

# SHARE_HISTORY keeps history synced across open shells.
# HIST_IGNORE_* skips duplicate commands and commands prefixed with a space.
# HIST_VERIFY loads history expansions into the prompt before running them.
# EXTENDED_HISTORY stores timestamps and command durations.
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_VERIFY EXTENDED_HISTORY

# Directory navigation
# AUTO_CD lets a bare directory path act like cd.
# AUTO_PUSHD records directory jumps in the stack; PUSHD_* keeps that stack tidy.
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# ─────────────────────────────────────────────────────────────
# 12. Interactive plugins (syntax highlighting must stay last)
# ─────────────────────────────────────────────────────────────
if (( _zinit_available )); then
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  zinit light Aloxaf/fzf-tab # Replace tab completion menu with fzf.
  zinit light zsh-users/zsh-autosuggestions # Suggest commands from history/completion.
  zinit light zsh-users/zsh-syntax-highlighting # Highlight commands as you type.
fi
export PATH="/opt/homebrew/sbin:$PATH"

# opencode
export PATH=/Users/msetsma/.opencode/bin:$PATH
