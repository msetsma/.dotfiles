# clipboard abstraction
# WSL2 uses clip.exe (Windows interop), macOS uses pbcopy
if (( IS_MAC )); then
  _clip() { pbcopy }
  alias -g copy='| pbcopy'
elif (( IS_WSL )); then
  _clip() { clip.exe }
  alias -g copy='| clip.exe'
else
  if command -v xclip &>/dev/null; then
    _clip() { xclip -selection clipboard }
    alias -g copy='| xclip -selection clipboard'
  fi
fi

# open abstraction
if (( IS_WSL )); then
  alias open='wslview'
elif ! (( IS_MAC )); then
  alias open='xdg-open'
fi

# general
alias c='clear'
alias home='cd $HOME'
alias dotfiles='cd ~/.dotfiles'
alias dev='cd ~/dev'
alias mlops='cd ~/dev/mlops'

# tool replacements
alias cat='bat'
alias grep='rg'
alias find='fd'

# EZA - better ls
alias ls='eza -1ah --group-directories-first --git-repos-no-status --icons --all'
alias lt='eza --icons --tree --level=1 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lt1='eza --icons --tree --level=1 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lt2='eza --icons --tree --level=2 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lt3='eza --icons --tree --level=3 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lta='eza --icons --tree --group-directories-first -h --long --no-permissions --no-user --no-time'
alias ltcopy='eza --tree | _clip'

# git
alias gitfzf='~/.config/bash/git_fzf_checkout.sh'

# because microsoft is dumb
alias az='PYTHONWARNINGS="ignore::UserWarning" az'

# databricks
alias db='databricks'
alias db-prod='_use_databricks prod'
alias db-qa='_use_databricks qa'
alias db-dev='_use_databricks dev'

# zellij
alias z='zellij'

# azure
alias repo='open $(az repos show --repository $(basename "$PWD") --query webUrl -o tsv)'

# lazy docker
alias lzd='lazydocker'

# completions for aliases (must run after compinit)
compdef db=databricks
compdef z=zellij
compdef cat=bat
compdef grep=rg
compdef find=fd
compdef ls=eza
compdef lt=eza lt1=eza lt2=eza lt3=eza lta=eza ltcopy=eza
compdef az=az
