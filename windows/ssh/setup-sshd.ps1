# Sets up the native Windows OpenSSH server for Moshi (needs admin).
# Logins land in nushell; run `wsl` from there to hop into Linux.
# Re-run safely; every step is idempotent.
param(
    [int]$Port = 22,
    [string]$Shell = (Join-Path $env:USERPROFILE "scoop\apps\nu\current\nu.exe"),
    # Defaults to the Moshi key already trusted by WSL's sshd.
    [string]$PublicKey = ""
)
$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting admin to configure sshd"
    $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"", "-Port", $Port, "-Shell", "`"$Shell`"")
    if ($PublicKey) { $argList += @("-PublicKey", "`"$PublicKey`"") }
    Start-Process powershell -Verb RunAs -Wait -ArgumentList $argList
    exit
}

# The elevated window closes on exit, so hold it open on failure.
trap {
    Write-Host $_ -ForegroundColor Red
    Read-Host "Setup failed. Press Enter to close"
    exit 1
}

if (-not (Test-Path $Shell)) { throw "Shell not found: $Shell" }
if (-not $PublicKey) {
    $PublicKey = (wsl.exe -e sh -c "grep -m1 moshi ~/.ssh/authorized_keys") | Select-Object -First 1
    if (-not $PublicKey) { throw "No Moshi key in WSL authorized_keys; pass -PublicKey" }
}

# 1. Install the server and let its first start generate sshd_config + host keys.
$cap = Get-WindowsCapability -Online -Name "OpenSSH.Server*"
if ($cap.State -ne "Installed") { Add-WindowsCapability -Online -Name $cap.Name | Out-Null }
Set-Service sshd -StartupType Automatic
$config = Join-Path $env:ProgramData "ssh\sshd_config"
if (-not (Test-Path $config)) { Start-Service sshd; Stop-Service sshd }

# 2. Port and key-only auth.
$text = Get-Content $config -Raw
$text = $text -replace "(?m)^#?Port\s+\d+", "Port $Port"
$text = $text -replace "(?m)^#?PasswordAuthentication\s+\w+", "PasswordAuthentication no"
# Only MOSHI_CLIENT may come from authorized_keys environment= options.
$text = $text -replace "(?m)^#?PermitUserEnvironment\s+\S+", "PermitUserEnvironment MOSHI_CLIENT"
Set-Content $config $text -NoNewline -Encoding ascii

# 3. Admin users read keys from ProgramData, and sshd rejects the file unless
#    only Administrators and SYSTEM can touch it.
#    The Moshi key sets MOSHI_CLIENT itself, since Moshi's "Export ENV" types
#    POSIX `export` lines that nushell can't run.
$keys = Join-Path $env:ProgramData "ssh\administrators_authorized_keys"
$entry = "environment=`"MOSHI_CLIENT=1`" $PublicKey"
$existing = if (Test-Path $keys) { @(Get-Content $keys) } else { @() }
$others = @($existing | Where-Object { $_ -and -not $_.EndsWith($PublicKey) })
Set-Content $keys ($others + $entry) -Encoding ascii
icacls.exe $keys /inheritance:r /grant "*S-1-5-32-544:F" /grant "*S-1-5-18:F" | Out-Null

# 4. Login shell.
New-Item -Path "HKLM:\SOFTWARE\OpenSSH" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value $Shell -PropertyType String -Force | Out-Null

# 5. Firewall.
$rule = "Windows SSH (Moshi)"
$stale = @($rule, "WSL SSH", "WSL Mosh UDP")
Get-NetFirewallRule | Where-Object DisplayName -in $stale | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName $rule -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -Profile Any | Out-Null

& (Join-Path $env:WINDIR "System32\OpenSSH\sshd.exe") -t
if ($LASTEXITCODE -ne 0) { throw "sshd_config failed validation" }
Restart-Service sshd

# 6. sshd sessions skip links made unelevated (dotter, scoop), so re-own them.
& (Join-Path $PSScriptRoot "trust-links.ps1")
Write-Host "sshd listening on $Port with shell $Shell"
