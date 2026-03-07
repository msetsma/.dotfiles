# Source env vars (not auto-sourced when ZDOTDIR is set via ~/.zshenv)
source "$HOME/.config/zsh/.zshenv"

# Source platform detection first
source "$HOME/.config/zsh/platform.zsh"

# Only set PATH once
if [ -z "$PATH_SET" ]; then
  if (( IS_MAC )); then
    export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/go/bin:$PATH"
  else
    export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/go/bin:$PATH"
    # Linuxbrew (if installed)
    [[ -d /home/linuxbrew/.linuxbrew ]] && export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
  fi
  export GOPATH="$HOME/go"
  export PATH="$PATH:$GOPATH/bin"
  export PATH_SET=1
fi

if grep -qi microsoft /proc/version 2>/dev/null; then
    # WSL
    export COPY_COMMAND="clip.exe"
else
    # Mac
    export COPY_COMMAND="pbcopy"
fi

export UV_VENV_CTEAR=1

# fpath setup (before compinit)
if (( IS_MAC )); then
  fpath+=("$(brew --prefix)/share/zsh/site-functions")
fi
_uv_comp_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$_uv_comp_dir"
[[ ! -f "$_uv_comp_dir/_uv" ]] && uv generate-shell-completion zsh > "$_uv_comp_dir/_uv" 2>/dev/null
[[ ! -f "$_uv_comp_dir/_uvx" ]] && uvx --generate-shell-completion zsh > "$_uv_comp_dir/_uvx" 2>/dev/null
fpath=("$_uv_comp_dir" $fpath)

autoload -Uz compinit && compinit

# Homebrew
if (( IS_MAC )); then
  export HOMEBREW_NO_ENV_HINTS=1
  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_INSTALL_CLEANUP=1
fi

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
(( $+commands[starship] )) && eval "$(starship init zsh)"

# Zellij pane renaming hooks - AFTER starship, BEFORE zellij auto-start
# so they don't interfere with starship's own prompt hooks
if [[ -n "$ZELLIJ" ]]; then
  preexec() {
      zellij action rename-pane "⚙ ${1%% *}"
  }
  precmd() {
      local name
      name=$(git rev-parse --show-toplevel 2>/dev/null)
      if [[ -n "$name" ]]; then
          name=$(basename "$name")
      else
          name=$(basename "$PWD")
      fi
      zellij action rename-pane "$name"
  }
fi

# zellij
(( $+commands[zellij] )) && eval "$(zellij setup --generate-auto-start zsh)"