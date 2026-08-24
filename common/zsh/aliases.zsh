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
alias ls='eza --grid -ah --group-directories-first --git-repos-no-status --icons --all'
alias lt='eza --icons --tree --level=1 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lt1='eza --icons --tree --level=1 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lt2='eza --icons --tree --level=2 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lt3='eza --icons --tree --level=3 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lta='eza --icons --tree --group-directories-first -h --long --total-size --no-permissions --no-user --no-time'
alias ltcopy='eza --tree | _clip'

# git
alias gfzf='~/.config/bash/git_checkout_fzf.sh'
alias gaa='git add .'
alias gs='git status'

# because microsoft is dumb
# alias az='PYTHONWARNINGS="ignore::UserWarning" az'

# databricks
alias db='databricks'
alias db-prod='_use_databricks prod'
alias db-qa='_use_databricks qa'
alias db-dev='_use_databricks dev'

# uv
alias uvt='uv tool'

# azure
alias entra='~/.config/bash/entra.sh'

# lazy docker
alias lzd='lazydocker'
alias lzg='lazygit'
