# Copies the autoconfig files into the Firefox install dir (needs admin).
# Re-run after a Firefox reinstall. Restart Firefox afterwards.
$ErrorActionPreference = "Stop"

$firefoxDir = Join-Path $env:ProgramFiles "Mozilla Firefox"
$source = Join-Path $PSScriptRoot "autoconfig"

if (-not (Test-Path (Join-Path $firefoxDir "firefox.exe"))) {
    throw "Firefox not found in $firefoxDir"
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting admin to write to $firefoxDir"
    Start-Process powershell -Verb RunAs -Wait -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
    exit
}

Copy-Item (Join-Path $source "mozilla.cfg") $firefoxDir -Force
Copy-Item (Join-Path $source "defaults\pref\autoconfig.js") (Join-Path $firefoxDir "defaults\pref") -Force
Write-Host "Installed Firefox autoconfig to $firefoxDir. Restart Firefox to apply."
