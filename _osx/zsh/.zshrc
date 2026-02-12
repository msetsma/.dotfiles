export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

export UV_VENV_CLEAR=1
export EDITOR="nvim"
export VISUAL="nvim"
export XDG_CONFIG_HOME="$HOME/.config"
export ZSH="$ZDOTDIR/ohmyzsh"

# homebrew
autoload -Uz compinit && compinit
compinit
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# go
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"

# rust
. "$HOME/.cargo/env"

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

eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"

# Load Variables and Functions
# source_folder_contents "$HOME/.config/bash/"
source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/functions.zsh"

# starship
eval "$(starship init zsh)"

fpath+=$(brew --prefix)/share/zsh/site-functions



source /Users/msetsma/.config/broot/launcher/bash/br
