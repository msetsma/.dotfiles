# Clear the loading time message
$ExecutionContext.Host.UI.RawUI.WindowTitle = "PowerShell"
$env:POWERSHELL_UPDATECHECK = "Off"

# Path to the symlinked folder (automatically set to the profile folder location)
$ProfileDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import aliases
. "$ProfileDirectory\aliases.ps1"

# Remove the default alias
if (Test-Path Alias:ls) {
    Remove-Item Alias:ls
}

# Import functions
. "$ProfileDirectory\functions.ps1"

# Starship
Invoke-Expression (&starship init powershell)

