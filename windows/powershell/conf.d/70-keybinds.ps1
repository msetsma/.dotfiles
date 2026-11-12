# Keybindings, mirroring common/zsh/keybindings.zsh plus the fzf zsh defaults.
#   ctrl-g cmds picker    ctrl-t insert files    ctrl-r fzf history
#   alt-c  zoxide jump    alt-h  line helper

if (-not (Get-Module PSReadLine)) { return }

function _rl-buffer {
    $line = $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [pscustomobject]@{ Line = $line; Cursor = $cursor }
}

function _rl-replace([string]$Text) {
    $rl = [Microsoft.PowerShell.PSConsoleReadLine]
    $rl::Replace(0, (_rl-buffer).Line.Length, $Text)
    $rl::EndOfLine()
}

Set-PSReadLineKeyHandler -Chord Ctrl+g -BriefDescription cmds -ScriptBlock {
    $pick = _cmds-pick
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    if ($pick) { _rl-replace $pick }
}

Set-PSReadLineKeyHandler -Chord Ctrl+t -BriefDescription fzf-files -ScriptBlock {
    $picks = _fzf-files
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    if ($picks) { [Microsoft.PowerShell.PSConsoleReadLine]::Insert((@($picks) -join ' ')) }
}

Set-PSReadLineKeyHandler -Chord Ctrl+r -BriefDescription fzf-history -ScriptBlock {
    $pick = _fzf-history (_rl-buffer).Line
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    if ($pick) { _rl-replace $pick }
}

Set-PSReadLineKeyHandler -Chord Alt+c -BriefDescription zoxide-pick -ScriptBlock {
    _rl-replace 'zi'
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Chord Alt+h -BriefDescription line-helper -ScriptBlock {
    $rl = [Microsoft.PowerShell.PSConsoleReadLine]
    $line = (_rl-buffer).Line
    $actions = [ordered]@{
        'copy line'     = { $line | copy }
        'cut line'      = { $line | copy; _rl-replace '' }
        'clear line'    = { _rl-replace '' }
        'jump to start' = { $rl::BeginningOfLine() }
        'jump to end'   = { $rl::EndOfLine() }
    }
    $pick = $actions.Keys | fzf --prompt 'line > ' --height 40%
    $rl::InvokePrompt()
    if ($pick) { & $actions[$pick] }
}

# zsh-style completion menu and prefix history search on the arrows
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
# Ctrl+_ undoes (Ghostty sends it for Cmd+Z)
Set-PSReadLineKeyHandler -Chord 'Ctrl+_' -Function Undo
