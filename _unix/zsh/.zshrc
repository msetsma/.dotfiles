export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

plugins=(
    git 
    sudo
    zsh-autosuggestions
    zsh-syntax-highlighting
)
source $ZSH/oh-my-zsh.sh

export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="nvim"

# zsh
source "$XDG_CONFIG_HOME/zsh/aliases.zsh"
source "$XDG_CONFIG_HOME/zsh/functions.zsh"

# go
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# rust
. "$HOME/.cargo/env"

# Starship Prompt
eval "$(starship init zsh)"
