# Recreates symlinks and junctions as admin so SSH sessions can follow them.
#
# sshd runs with RedirectionGuard, and its children (nu, starship, ...) refuse
# links made by a non-elevated user: "The path cannot be traversed because it
# contains an untrusted mount point". dotter and scoop both create links
# unelevated, so re-run this after `dotter deploy` adds links or `scoop update`
# swaps an app's `current` junction. Re-run safely; trusted links are skipped.
param(
    [string[]]$Roots = @(
        (Join-Path $env:USERPROFILE ".config"),
        (Join-Path $env:USERPROFILE ".glance"),
        (Join-Path $env:USERPROFILE "AppData\Local\nvim")
    ),
    [string]$ScoopApps = (Join-Path $env:USERPROFILE "scoop\apps")
)
$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting admin to recreate links"
    Start-Process powershell -Verb RunAs -Wait -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
    exit
}

trap {
    Write-Host $_ -ForegroundColor Red
    Read-Host "Failed. Press Enter to close"
    exit 1
}

# Walks a tree without descending into links, yielding every link found.
function Find-Links([string]$Dir) {
    foreach ($item in Get-ChildItem -LiteralPath $Dir -Force -ErrorAction SilentlyContinue) {
        if ($item.LinkType) { $item }
        elseif ($item.PSIsContainer) { Find-Links $item.FullName }
    }
}

# icacls enforces RedirectionGuard itself, so it fails exactly where sshd would.
# A directory link is only checked when traversed, hence the `\*`.
function Test-Untrusted($Link) {
    $path = if ($Link.PSIsContainer) { Join-Path $Link.FullName "*" } else { $Link.FullName }
    # Via cmd so PowerShell 5 doesn't turn icacls' stderr into a terminating error.
    (cmd.exe /c "icacls `"$path`" 2>&1" | Out-String) -match "untrusted mount point"
}

$links = @($Roots | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object {
    $root = Get-Item -LiteralPath $_ -Force
    if ($root.LinkType) { $root } else { Find-Links $root.FullName }
})
$links += @(Get-ChildItem -LiteralPath $ScoopApps -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { Get-Item -LiteralPath (Join-Path $_.FullName "current") -Force -ErrorAction SilentlyContinue } |
    Where-Object LinkType)

$fixed = 0
foreach ($link in $links) {
    if (-not (Test-Untrusted $link)) { continue }
    $path, $type, $target = $link.FullName, $link.LinkType, @($link.Target)[0]
    # New-Item can't recreate a dangling link, so leave dead ones alone.
    if (-not (Test-Path -LiteralPath $target)) { Write-Host "skipped dangling $path -> $target"; continue }
    # scoop marks `current` read-only; keep that flag on the replacement.
    $readOnly = $link.Attributes -band [IO.FileAttributes]::ReadOnly
    if ($readOnly) { attrib.exe -R /L $path }
    # Directory/File.Delete remove only the link, never what it points at.
    if ($link.PSIsContainer) { [IO.Directory]::Delete($path) } else { [IO.File]::Delete($path) }
    New-Item -ItemType $type -Path $path -Target $target | Out-Null
    if ($readOnly) { attrib.exe +R /L $path }
    if (Test-Untrusted (Get-Item -LiteralPath $path -Force)) { throw "Still untrusted after recreate: $path" }
    Write-Host "trusted $path -> $target"
    $fixed++
}
Write-Host "$fixed of $($links.Count) links recreated"
Read-Host "Press Enter to close"
