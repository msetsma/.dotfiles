# Aliases, mirroring common/zsh/aliases.zsh.
#
# nu's own `ls`, `find` and `open` return structured data and are worth keeping,
# so eza lives on `l`/`lt*` and fd stays `fd` instead of shadowing them.

alias c = clear
alias home = cd ~
alias dotfiles = cd ~/.dotfiles
alias dev = cd ~/dev

alias cat = bat
alias grep = rg

alias l = eza --grid -ah --group-directories-first --git-repos-no-status --icons --all
alias lt = eza --icons --tree --level=1 --group-directories-first -h --long --no-permissions --no-user --no-time
alias lt1 = eza --icons --tree --level=1 --group-directories-first -h --long --no-permissions --no-user --no-time
alias lt2 = eza --icons --tree --level=2 --group-directories-first -h --long --no-permissions --no-user --no-time
alias lt3 = eza --icons --tree --level=3 --group-directories-first -h --long --no-permissions --no-user --no-time
alias lta = eza --icons --tree --group-directories-first -h --long --total-size --no-permissions --no-user --no-time

alias gaa = git add .
alias gs = git status

alias uvt = uv tool
alias lzg = lazygit
alias lzd = lazydocker
