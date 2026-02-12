export PATH="/usr/local/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

export UV_VENV_CLEAR=1
export EDITOR="nvim"
export VISUAL="nvim"
export XDG_CONFIG_HOME="$HOME/.config"
export ZSH="$ZDOTDIR/ohmyzsh"

# Load Variables and Functions
source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/functions.zsh"
# source_folder_contents "$HOME/.config/bash/"

# go
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"

# rust
. "$HOME/.cargo/env"

# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh 
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  aliases
  fzf-tab
  git
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

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
