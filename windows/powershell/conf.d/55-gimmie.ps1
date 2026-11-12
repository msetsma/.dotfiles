# gimmie: fuzzy-find files under a root and move (or copy) them here.
# Port of common/zsh/functions/public/gimmie.
#
#   gimmie [root] [-d N | -a] [-r 2d] [-Dirs] [-c]
#   gimmie undo   reverse the last run (moves go back, copies get deleted)
#
# PowerShell flags are case-insensitive, so zsh's -D (folders) is -Dirs here.
# A name clash brings the file in as "name (1).ext"; nothing is overwritten.
# Keys: Tab multi-select, ctrl-o open, ctrl-y copy path, ctrl-/ preview,
#       ctrl-d add folders, ctrl-f files only.

$GimmieLog = Join-Path $HOME '.local/state/gimmie/last'

function _gimmie-free-path([IO.FileSystemInfo]$Item) {
    $name = $Item.Name
    $stem = [IO.Path]::GetFileNameWithoutExtension($name)
    $ext = [IO.Path]::GetExtension($name)
    $dst = Join-Path $PWD $name
    $n = 1
    while (Test-Path -LiteralPath $dst) {
        # Folders and dotfiles like ".zshrc" get the number at the end
        $dst = if ($Item.PSIsContainer -or -not $stem -or -not $ext) { Join-Path $PWD "$name ($n)" }
               else { Join-Path $PWD "$stem ($n)$ext" }
        $n++
    }
    $dst
}

# Each log line is "<mv|cp>`t<original path>`t<new path>"
function _gimmie-undo {
    if (-not (Test-Path $GimmieLog) -or -not (Get-Content $GimmieLog)) {
        Write-Host 'Nothing to undo' -ForegroundColor Yellow; return
    }
    foreach ($line in Get-Content $GimmieLog) {
        $op, $src, $dst = $line -split "`t"
        if (-not (Test-Path -LiteralPath $dst)) { Write-Host "Skipped (gone): $dst" -ForegroundColor Yellow }
        elseif ($op -eq 'cp') { Remove-Item -LiteralPath $dst -Recurse -Force; Write-Host "Removed copy: $dst" -ForegroundColor Green }
        elseif (Test-Path -LiteralPath $src) { Write-Host "Skipped (original spot taken): $src" -ForegroundColor Yellow }
        else {
            $null = New-Item -ItemType Directory -Force (Split-Path $src)
            Move-Item -LiteralPath $dst -Destination $src
            Write-Host "Restored: $src" -ForegroundColor Green
        }
    }
    Remove-Item $GimmieLog
}

# .SYNOPSIS
# Fuzzy-find files under a root (default ~) and move or copy them here
function gimmie {
    param(
        [string]$Root = $HOME,
        [Alias('d')][int]$Depth = 5,
        [Alias('a')][switch]$All,
        [Alias('r')][string]$Recent,
        [switch]$Dirs,
        [Alias('c')][switch]$Copy
    )
    if ($Root -eq 'undo') { _gimmie-undo; return }
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { throw "Not a directory: $Root" }

    $fdArgs = @('--hidden', '--exclude', '.git', '--exclude', 'node_modules', '--absolute-path')
    if (-not $All) { $fdArgs += '--max-depth', $Depth }
    if ($Recent) { $fdArgs += '--changed-within', $Recent }
    $fdArgs += '.', (Resolve-Path -LiteralPath $Root).Path, '--type', 'f'
    # fzf reload runs through $SHELL or cmd.exe, so pass it one quoted line
    $files = 'fd ' + (($fdArgs | ForEach-Object { "`"$_`"" }) -join ' ')
    $both = "$files --type d"

    $verb, $done = if ($Copy) { 'Copy', 'Copied' } else { 'Move', 'Moved' }
    $first = if ($Dirs) { $fdArgs + '--type', 'd' } else { $fdArgs }
    $picked = fd @first 2>$null |
        fzf --multi --prompt $(if ($Dirs) { 'gimmie +dirs > ' } else { 'gimmie > ' }) `
            --header "$verb into $($PWD.Path.Replace($HOME, '~'))`n^o open  ^y copy path  ^/ preview  ^d folders  ^f files" `
            --keep-right --preview-window right:60%:wrap `
            --preview 'bat --color=always --style=numbers --line-range=:80 {} 2>nul || eza --tree --level=2 --icons --color=always {}' `
            --bind 'ctrl-o:execute-silent(explorer.exe {})' `
            --bind 'ctrl-y:execute-silent(echo {}| clip)' `
            --bind 'ctrl-/:toggle-preview' `
            --bind "ctrl-d:change-prompt(gimmie +dirs > )+reload($both)" `
            --bind "ctrl-f:change-prompt(gimmie > )+reload($files)"
    if (-not $picked) { return }

    $null = New-Item -ItemType Directory -Force (Split-Path $GimmieLog)
    $log = foreach ($path in @($picked)) {
        $path = $path.TrimEnd('\', '/')  # fd prints folders with a trailing slash
        if (-not (Test-Path -LiteralPath $path)) {
            Write-Host "Skipped (moved with its folder): $path" -ForegroundColor Yellow; continue
        }
        $item = Get-Item -LiteralPath $path -Force
        $dst = _gimmie-free-path $item
        if ($Copy) { Copy-Item -LiteralPath $path -Destination $dst -Recurse } else { Move-Item -LiteralPath $path -Destination $dst }
        "$(if ($Copy) { 'cp' } else { 'mv' })`t$path`t$dst"
        $as = if ((Split-Path $dst -Leaf) -ne $item.Name) { " as $(Split-Path $dst -Leaf)" } else { '' }
        Write-Host "$($PSStyle.Foreground.Green)${done}:$($PSStyle.Reset) $path$as"
    }
    $log | Set-Content $GimmieLog
}
