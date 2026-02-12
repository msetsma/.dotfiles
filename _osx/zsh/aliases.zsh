# general
alias c='clear'
alias home='cd $home'
alias dotfiles='cd ~/.dotfiles'

# google cloud platform
alias gc-svm='~/_scripts/gcloud/svm_manage.sh'
alias gc-proj='~/_scripts/gcloud/set_project.sh'
alias gc-setup='~/_scripts/gcloud/_setup.sh'
alias gc-auth='~/_scripts/gcloud/auth_login.sh'

# python
alias py='python3'
alias python='python3'

# EZA - better ls
alias ls='eza -ah --git-repos-no-status --icons'
alias lt1='eza --icons --tree --level=1 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lt2='eza --icons --tree --level=2 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lt3='eza --icons --tree --level=3 --group-directories-first -h --long --no-permissions --no-user --no-time'
alias lta='eza --icons --tree --group-directories-first -h --long --no-permissions --no-user --no-time'
alias ltcopy='eza --tree | pbcopy'

# reload .zsh
alias reload='source ~/.zshrc; aerospace reload-config'
