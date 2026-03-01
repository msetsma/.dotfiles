# Only set PATH once
if [ -z "$PATH_SET" ]; then
  export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/go/bin:$PATH"
  export GOPATH="$HOME/go"
  export PATH="$PATH:$GOPATH/bin"
  export PATH_SET=1
fi

export UV_VENV_CTEAR=1

# fpath setup (before compinit)
fpath+=("$(brew --prefix)/share/zsh/site-functions")
_uv_comp_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$_uv_comp_dir"
[[ ! -f "$_uv_comp_dir/_uv" ]] && uv generate-shell-completion zsh > "$_uv_comp_dir/_uv" 2>/dev/null
[[ ! -f "$_uv_comp_dir/_uvx" ]] && uvx --generate-shell-completion zsh > "$_uv_comp_dir/_uvx" 2>/dev/null
fpath=("$_uv_comp_dir" $fpath)

# homebrew
autoload -Uz compinit && compinit
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# Oh My Zsh
plugins=(
  fzf-tab
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
)
source $ZSH/oh-my-zsh.sh


# fzf
[ -f "$HOME/.fzf.zsh" ] && source <(fzf --zsh)
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_DEFAULT_COMMAND='rg --hidden -l ""' # Include hidden files

# Load aliases
source "$HOME/.config/zsh/aliases.zsh"

# Autoload functions
fpath=($HOME/.config/zsh/functions $fpath)
for func_file in $HOME/.config/zsh/functions/*; do
  [[ -f "$func_file" ]] && autoload -Uz ${func_file:t}
done

# starship
eval "$(starship init zsh)"

# Zellij pane renaming hooks - AFTER starship, BEFORE zellij auto-start
# so they don't interfere with starship's own prompt hooks
if [[ -n "$ZELLIJ" ]]; then
  function preexec() {
      [[ -n "$ZELLIJ" ]] && zellij action rename-pane "⚙ ${1%% *}"
  }
  function precmd() {
      if [[ -n "$ZELLIJ" ]]; then
          # project root is more stable than pwd basename
          local name=$(git rev-parse --show-toplevel 2>/dev/null | xargs basename || basename $PWD)
          zellij action rename-pane "$name"
      fi
  }
fi

# zellij
eval "$(zellij setup --generate-auto-start zsh)"
