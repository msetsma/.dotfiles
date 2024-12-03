# EZA - better ls
function ls {
    eza --icons --group-directories-first -h --long --no-permissions --no-user --no-time
}

function lt1 {
    eza --icons --tree --level=1 --group-directories-first -h --long --no-permissions --no-user --no-time
}
function lt2 {
    eza --icons --tree --level=2 --group-directories-first -h --long --no-permissions --no-user --no-time
}
function lt3 {
    eza --icons --tree --level=3 --group-directories-first -h --long --no-permissions --no-user --no-time
}
function lta {
    eza --icons --tree --group-directories-first -h --long --no-permissions --no-user --no-time
}

# Reload PowerShell profile
function reload {
    . $PROFILE
}