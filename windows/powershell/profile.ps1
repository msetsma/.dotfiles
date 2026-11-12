# PowerShell 7 profile (CurrentUserAllHosts). A thin loader: everything lives
# in ~/.config/powershell/conf.d/*.ps1, dot-sourced in name order.
#
# Non-interactive sessions (scripts, agents running `pwsh -NonInteractive`)
# skip it all so aliases like cat=bat and ls=eza never leak into automation.

$nonInteractive = [Environment]::GetCommandLineArgs() | Where-Object { $_ -match '^-noni' }
if ($nonInteractive -or -not [Environment]::UserInteractive) { return }

$PowerShellConfigDir = Join-Path $HOME '.config' 'powershell'
foreach ($file in Get-ChildItem (Join-Path $PowerShellConfigDir 'conf.d') -Filter *.ps1 | Sort-Object Name) {
    . $file.FullName
}
Remove-Variable file, nonInteractive -ErrorAction SilentlyContinue
