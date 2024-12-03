# Create symbolic link for Starship config
if (Test-Path "$HOME\.config\starship.toml") {
    Remove-Item "$HOME\.config\starship.toml"
}
New-Item -ItemType SymbolicLink -Path "$HOME\.config\starship.toml" -Target "$PWD\starship\starship.toml"

# Create symbolic link for the WezTerm folder
if (Test-Path "$HOME\.config\wezterm") {
    Remove-Item "$HOME\.config\wezterm" -Recurse -Force
}
if (Test-Path "$PWD\wezterm") {
    New-Item -ItemType SymbolicLink -Path "$HOME\.config\wezterm" -Target "$PWD\wezterm"
} else {
    Write-Error "WezTerm folder not found: $PWD\wezterm"
}

# Copy PowerShell profile
# Explicitly define the source file path and destination
$sourceProfilePath = "$PWD\powershell"
$destinationProfilePath = "$HOME\Documents\WindowsPowerShell"

# Create symbolic link for the WezTerm folder
if (Test-Path $destinationProfilePath) {
    Remove-Item $destinationProfilePath -Recurse -Force
}
if (Test-Path $sourceProfilePath) {
    New-Item -ItemType SymbolicLink -Path $destinationProfilePath -Target $sourceProfilePath
} else {
    Write-Error "PowerShell folder not found: $sourceProfilePath"
}

