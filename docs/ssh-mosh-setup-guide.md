# iPhone → WSL SSH/Mosh Setup via Tailscale

## Architecture
```
Moshi (iPhone) → Mosh/SSH → Tailscale → Windows (mirrored networking) → WSL → tmux → your code
```

## Prerequisites
- Tailscale installed and authenticated on both iPhone and Windows PC
- WSL2 with a Linux distro installed
- Moshi app on iPhone with an Ed25519 key generated

---

## 1. Enable Mirrored Networking in WSL2

Create/edit `C:\Users\<your-user>\.wslconfig`:

```ini
[wsl2]
networkingMode=mirrored
```

Restart WSL from PowerShell:

```powershell
wsl --shutdown
```

This lets WSL share the Windows network stack so ports opened inside WSL are reachable via the Windows Tailscale IP.

---

## 2. Install OpenSSH Server and Mosh in WSL

```bash
sudo apt update
sudo apt install openssh-server mosh
```

---

## 3. Configure sshd

Edit `/etc/ssh/sshd_config` — place these lines **at the top** of the file, before any `Include` directives:

```
Port 22
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
MaxAuthTries 3
AllowUsers <your-wsl-username>
```

Replace `<your-wsl-username>` with the output of `whoami`.

---

## 4. Generate SSH Host Keys

```bash
sudo ssh-keygen -A
```

---

## 5. Add Moshi Public Key to WSL

Copy the public key from Moshi (found in the app's key management section). Then in WSL:

```bash
mkdir -p ~/.ssh
echo "<your-moshi-public-key>" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

## 6. Start sshd

```bash
sudo mkdir -p /run/sshd && sudo /usr/sbin/sshd -p 22
```

Note: `/run/sshd` is cleared on every WSL restart and must be recreated.

---

## 7. Automate sshd on WSL Boot

Edit `/etc/wsl.conf`:

```ini
[boot]
systemd=true
command=mkdir -p /run/sshd && /usr/sbin/sshd -p 22
```

---

## 8. Windows Firewall Rules

In an elevated PowerShell:

```powershell
New-NetFirewallRule -DisplayName "WSL Mosh UDP" -Direction Inbound -LocalPort 60000-61000 -Protocol UDP -Action Allow
```

If SSH also needs a rule:

```powershell
New-NetFirewallRule -DisplayName "WSL SSH" -Direction Inbound -LocalPort 22 -Protocol TCP -Action Allow
```

---

## 9. Disable Windows OpenSSH Server (Optional)

If you previously enabled the Windows OpenSSH server and no longer need it:

```powershell
Stop-Service sshd
Set-Service -Name sshd -StartupType Disabled
```

---

## 10. Configure Moshi on iPhone

- **Host**: PC's Tailscale IP (find with `tailscale ip` in PowerShell)
- **Port**: 22
- **Username**: your WSL username
- **Auth**: the Ed25519 key you generated in Moshi
- **Connection type**: Mosh

---

## 11. Install tmux for Session Persistence

```bash
sudo apt install tmux
```

Usage:
- Start a session: `tmux new -s work`
- Detach: `Ctrl+B` then `D`
- Reattach after reconnecting: `tmux attach -t work`

---

## Troubleshooting

- **sshd won't start**: Check `sudo sshd -t` for config errors. Ensure `/run/sshd` exists.
- **Port already in use**: Run `sudo pkill sshd` then restart. Check Windows side with `netstat -ano | findstr <port>` in PowerShell.
- **Mosh connection fails**: Verify UDP firewall rule exists. Confirm mirrored networking is active in `.wslconfig`.
- **Permission denied**: Verify `authorized_keys` permissions (700 on `.ssh`, 600 on the file). Confirm `AllowUsers` matches your username.
- **Connection hangs**: sshd likely isn't running. Start it manually with `sudo mkdir -p /run/sshd && sudo /usr/sbin/sshd -p 22`.
