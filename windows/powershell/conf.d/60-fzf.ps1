# fzf pickers: cmds, history, file insert, line helper.
# Ported from windows/nushell/autoload/50-fzf.nu; bound to keys in 70-keybinds.ps1.

# One-line description of a dotfiles function: its .SYNOPSIS, else its body
function _cmds-detail([System.Management.Automation.FunctionInfo]$Command) {
    $help = $Command.ScriptBlock.Ast.GetHelpContent()
    if ($help -and $help.Synopsis) { return $help.Synopsis.Trim() }
    ($Command.Definition.Trim() -split "`n")[0].Trim()
}

function _history-lines {
    $file = (Get-PSReadLineOption).HistorySavePath
    if (Test-Path $file) { [IO.File]::ReadAllLines($file) }
}

# Rows for the cmds picker: dotfiles functions, then most-used history commands
function _cmds-rows([int]$Count) {
    $confDir = Join-Path $PowerShellConfigDir 'conf.d'
    $commands = Get-Command -CommandType Function |
        Where-Object { $_.ScriptBlock.File -and (Split-Path $_.ScriptBlock.File) -eq $confDir -and -not $_.Name.StartsWith('_') } |
        ForEach-Object { [pscustomobject]@{ Name = $_.Name; Detail = _cmds-detail $_ } }
    $topHistory = _history-lines |
        ForEach-Object { ($_ -split ' ', 2)[0] } |
        Where-Object { $_ } |
        Group-Object -NoElement |
        Sort-Object Count -Descending |
        Select-Object -First $Count |
        ForEach-Object { [pscustomobject]@{ Name = $_.Name; Detail = "used $($_.Count) times" } }

    $seen = @{}
    @($commands) + @($topHistory) | Where-Object { -not $seen.ContainsKey($_.Name) -and ($seen[$_.Name] = $true) }
}

# fzf over _cmds-rows; returns the pick, or copies it on ctrl-y
function _cmds-pick([int]$Count = 75) {
    $rows = _cmds-rows $Count
    $width = ($rows.Name | Measure-Object -Property Length -Maximum).Maximum
    $cyan, $gray, $reset = "`e[1;36m", "`e[90m", $PSStyle.Reset
    $out = $rows |
        ForEach-Object { "$cyan$($_.Name.PadRight($width))$reset  $gray$($_.Detail)$reset`t$($_.Name)" } |
        fzf --ansi --prompt 'cmds > ' --header 'enter inserts / ctrl-y copies' --delimiter "`t" `
            --with-nth 1 --accept-nth 2 --expect ctrl-y --height 70%
    if (@($out).Count -lt 2) { return }

    $key, $pick = $out
    if ($key -eq 'ctrl-y') { $pick | copy; return }
    $pick
}

# .SYNOPSIS
# Fuzzy search dotfiles commands and most-used history (ctrl-g inserts it at the prompt)
function cmds {
    param([int]$Count = 75)
    $pick = _cmds-pick $Count
    if (-not $pick) { return }
    # Typed, there is no command line to edit, so hand the pick to the clipboard
    $pick | copy
    Write-Host "$pick $($PSStyle.Foreground.BrightBlack)(copied; ctrl-g inserts instead)$($PSStyle.Reset)"
}

# Fuzzy-pick a command from history, newest first
function _fzf-history([string]$Query) {
    $seen = @{}
    $lines = _history-lines
    if (-not $lines) { return }
    [array]::Reverse($lines)
    $lines | Where-Object { $_ -and -not $seen.ContainsKey($_) -and ($seen[$_] = $true) } |
        fzf --prompt 'history > ' --scheme history --height 50% --query $Query
}

# Fuzzy-pick file paths (bat preview, ctrl-/ toggles it), quoted when needed
function _fzf-files {
    fzf --multi --walker-skip .git,node_modules,target --preview 'bat -n --color=always {}' `
        --bind 'ctrl-/:change-preview-window(down|hidden|)' |
        ForEach-Object { if ($_ -match '\s') { "'$_'" } else { $_ } }
}
