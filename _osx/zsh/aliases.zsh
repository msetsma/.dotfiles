# general
alias c='clear'
alias home='cd $home'
alias dotfiles='cd ~/.dotfiles'

# EZA - better ls
alias ls='eza -1ah --git-repos-no-status --icons'
alias lt1='eza --icons --tree --level=1 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lt2='eza --icons --tree --level=2 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lt3='eza --icons --tree --level=3 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lta='eza --icons --tree --group-directories-first -h --long --no-permissions --no-user --no-time'
alias ltcopy='eza --tree | pbcopy'

# git
alias gfc='git_fzf_checkout'

# python
alias py='python3'
alias python='python3'
alias venv='manage_project_venv'

# databricks
alias db='databricks'