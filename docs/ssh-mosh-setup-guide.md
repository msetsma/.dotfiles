# iPhone → Windows SSH Setup via Tailscale

```
Moshi (iPhone) → SSH :22 → Tailscale → Windows sshd → nushell → herdr → claude
                                                          └─ `wsl` when Linux is needed
```

SSH only: there is no native Windows mosh-server.

## Prerequisites

- Tailscale installed and signed in on both iPhone and Windows
- Moshi app on iPhone with an Ed25519 key
- nushell and herdr installed (scoop / herdr.dev)

## 1. sshd

From any shell (prompts for UAC):

```powershell
powershell -File windows/ssh/setup-sshd.ps1 -PublicKey "<moshi public key>"
```

Installs OpenSSH Server on port 22 with key-only auth, sets nushell as the login shell, writes the
key to `C:\ProgramData\ssh\administrators_authorized_keys` (admin users read keys from there, not
`~/.ssh`), and opens the firewall. Safe to re-run.

## 2. moshi-hook (notifications)

Native Windows builds are experimental and only support Herdr. Defender flags the vendor's
`irm | iex` one-liner, so download the installer and run it as a file:

```powershell
irm https://getmoshi.app/install.ps1 -OutFile $env:TEMP\moshi-install.ps1
powershell -NoProfile -File $env:TEMP\moshi-install.ps1
# new terminal
moshi-hook install --target claude
moshi-hook pair --token <token from app: Settings -> Integrations>
moshi-hook service install
moshi-hook status   # expect: paired
```

## 3. Moshi app

- **Host**: Tailscale IP (`tailscale ip -4`) or MagicDNS name
- **Port**: 22
- **User**: Windows username (`$env:USERNAME`)
- **Auth**: the Ed25519 key from step 1
- **Connection type**: SSH

Run agents inside Herdr so notifications can target the pane.

## Troubleshooting

- **Timeout**: nothing reached sshd. Portmaster blocks inbound by default, below Windows Firewall
  and without logging there: in Portmaster, open sshd's app settings, disable *Block Inbound
  Connections*, optionally with incoming rule `+ 100.64.0.0/10` (tailnet only). Otherwise check
  Tailscale is connected on the phone, then
  `Get-WinEvent -LogName OpenSSH/Operational -MaxEvents 10` for attempts from the phone's 100.x IP.
- **Permission denied**: key missing or file ACL loosened. Re-run step 1.
- **Invalid user**: wrong username in the app.
