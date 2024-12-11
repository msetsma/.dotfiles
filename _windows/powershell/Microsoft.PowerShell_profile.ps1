# Clear the loading time message
$ExecutionContext.Host.UI.RawUI.WindowTitle = "PowerShell"

# Path to the symlinked folder (automatically set to the profile folder location)
$ProfileDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import aliases
. "$ProfileDirectory\aliases.ps1"

# Import functions
. "$ProfileDirectory\functions.ps1"

# Starship
Invoke-Expression (&starship init powershell)

