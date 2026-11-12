# Tool init: starship, zoxide, carapace, vivid LS_COLORS, PSReadLine options.
#
# Init scripts are generated once into ~/.cache/powershell instead of on every
# startup. After upgrading one of these tools run `rld -Regen`.
# mise is absent on purpose (as in nushell): its shims dir on PATH covers it.

$PowerShellCacheDir = Join-Path $HOME '.cache/powershell'
$null = New-Item -ItemType Directory -Force $PowerShellCacheDir

$vendorGenerators = [ordered]@{
    starship = { starship init powershell --print-full-init }
    zoxide   = { zoxide init powershell }
    carapace = { carapace _carapace powershell }
    vivid    = { "`$env:LS_COLORS = '$((vivid generate catppuccin-mocha).Trim())'" }
}

foreach ($tool in $vendorGenerators.Keys) {
    if (-not (Get-Command $tool -CommandType Application -ErrorAction SilentlyContinue)) { continue }
    $target = Join-Path $PowerShellCacheDir "$tool.ps1"
    if (-not (Test-Path $target)) {
        & $vendorGenerators[$tool] | Out-String | Set-Content -Path $target -Encoding utf8
    }
    . $target
}
Remove-Variable tool, target, vendorGenerators -ErrorAction SilentlyContinue

if (Get-Module PSReadLine) {
    Set-PSReadLineOption -EditMode Emacs -BellStyle None -HistoryNoDuplicates `
        -MaximumHistoryCount 50000 -HistorySearchCursorMovesToEnd
    # Predictions need a real console; they throw when output is redirected
    if (-not [Console]::IsOutputRedirected) {
        Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView
    }
    # Leading space keeps a command out of history, like zsh HIST_IGNORE_SPACE
    Set-PSReadLineOption -AddToHistoryHandler {
        param([string]$line)
        -not $line.StartsWith(' ')
    }
}
