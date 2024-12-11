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

function home {
    Set-Location $HOME
}

function touch($file) { "" | Out-File $file -Encoding ASCII }

# Sudo
function sudo() {
    if ($args.Length -eq 1) {
        start-process $args[0] -verb "runAs"
    }
    if ($args.Length -gt 1) {
        start-process $args[0] -ArgumentList $args[1..$args.Length] -verb "runAs"
    }
}