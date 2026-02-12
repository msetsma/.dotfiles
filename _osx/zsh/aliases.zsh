# general
alias c='clear'
alias home='cd $home'
alias dotfiles='cd ~/.dotfiles'
alias dev='cd ~/dev'
alias mlops='cd ~/dev/mlops'
alias copy='| pbcopy'

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
alias ltcopy='eza --tree | pbcopy'

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