# Path to the symlinked folder (automatically set to the profile folder location)
$ProfileDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import aliases
. "$ProfileDirectory\aliases.ps1"

# Import functions
. "$ProfileDirectory\functions.ps1"

[Environment]::SetEnvironmentVariable("POWERSHELL_UPDATECHECK", "Off", "User")

Invoke-Expression (&starship init powershell)

