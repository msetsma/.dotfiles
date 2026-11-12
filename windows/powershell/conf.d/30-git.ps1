# Git helpers: gcm, gfzf, gitnav, repo. Ported from windows/nushell/autoload/20-git.nu.
#
# fzf runs --preview through $SHELL (Git Bash) or cmd.exe, so previews stay
# plain `git ... && git ...` lines that parse in both.

# .SYNOPSIS
# Commit staged changes with a one-line message
function gcm {
    $msg = ($args -join ' ').Trim()
    if (-not $msg) { throw 'usage: gcm <commit message>' }
    git commit -m $msg
}

# .SYNOPSIS
# Fuzzy-pick a local or remote branch (most recent first) and check it out
function gfzf {
    $branches = git for-each-ref --sort=-committerdate refs/heads/ refs/remotes/ '--format=%(refname:short)' |
        Where-Object { $_ -notmatch 'HEAD$' }
    if (-not $branches) { throw 'no branches found' }

    $pick = $branches | fzf --no-hscroll --ansi --preview-window right:60% `
        --preview 'git log --graph --oneline --decorate --color=always -20 {1}'
    if (-not $pick) { return }
    Write-Host "Checking out branch: $pick"
    git checkout $pick
}

# .SYNOPSIS
# Fuzzy-jump to a git repo under a root (cached for 5 minutes)
function gitnav {
    param(
        [string]$Root = $(if ($env:GITNAV_ROOT) { $env:GITNAV_ROOT } else { $HOME }),
        [switch]$Force
    )
    $Root = (Resolve-Path $Root).Path
    $hash = [Convert]::ToHexString([Security.Cryptography.MD5]::HashData([Text.Encoding]::UTF8.GetBytes($Root)))
    $cache = Join-Path $HOME ".cache/gitnav/$hash.txt"
    $fresh = (Test-Path $cache) -and ((Get-Date) - (Get-Item $cache).LastWriteTime).TotalMinutes -lt 5

    if ($fresh -and -not $Force) {
        $listing = Get-Content $cache
    } else {
        Write-Host "scanning $Root for repos..." -ForegroundColor DarkGray
        $listing = fd --type d --hidden --no-ignore --max-depth 5 '^\.git$' $Root |
            ForEach-Object { Split-Path ($_.TrimEnd('\', '/')) -Parent } |
            Sort-Object { Split-Path $_ -Leaf } |
            ForEach-Object { "$(Split-Path $_ -Leaf)`t$_" }
        $null = New-Item -ItemType Directory -Force (Split-Path $cache)
        $listing | Set-Content $cache
    }
    if (-not $listing) { throw "no git repositories found in $Root" }

    $pick = $listing | fzf --prompt 'repo > ' --delimiter "`t" --with-nth 1 --accept-nth 2 --no-sort `
        --preview-window right:60%:wrap `
        --preview 'git -C {2} -c color.status=always status -sb && git -C {2} log --oneline --color=always -8'
    if (-not $pick) { return }

    Set-Location $pick
    $branch = git branch --show-current
    Write-Host "$($PSStyle.Foreground.Green)✓$($PSStyle.Reset) $(Split-Path $pick -Leaf) $($PSStyle.Foreground.Yellow)$branch$($PSStyle.Reset)"
}

# .SYNOPSIS
# Open the origin remote in the browser (GitHub only)
function repo {
    $remote = git remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0) { throw "no 'origin' remote found" }

    $url = $remote.Trim() -replace '\.git$', ''
    if ($url -notmatch '^(?:git@|ssh://git@|https://(?:[^@/]+@)?)github\.com[^:/]*[:/](?<path>.+)$') {
        throw "unsupported remote: $url"
    }
    Start-Process "https://github.com/$($Matches.path)"
}
