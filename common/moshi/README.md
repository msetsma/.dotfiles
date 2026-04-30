# common/moshi

Moshi remote-coding integration for this repo.

## Files

- `hook-runner.sh` — gated wrapper invoked by Claude Code hooks
  (see `common/claude/settings.json`). Fires `bunx moshi-hooks` only when a
  Moshi client is attached to the current tmux server. Skips silently
  during local development at the computer.

## Token

`moshi-hooks` reads the API token from `~/.config/moshi/token` (NOT
checked into this repo — secret). Generate one in the Moshi iOS app
(Settings -> Integrations -> Claude Code) and write it locally:

```bash
mkdir -p ~/.config/moshi
echo "<your-token>" > ~/.config/moshi/token
chmod 600 ~/.config/moshi/token
```

Or run the upstream installer once:

```bash
bunx moshi-hooks token <YOUR_TOKEN>
```

## How session continuity works

Two-session model in `common/zsh/.zshrc`:

- **Local** (WezTerm/Ghostty) -> tmux session `main`
- **Remote** (mosh/ssh) -> tmux session `mobile`

Same tmux server, separate sessions. No mirroring between desk and
phone, no viewport fights. Each location preserves its own continuity:
detach on phone, reattach later from phone -> same `mobile` state.
PC keeps `main` independently.

The `moshi <dir>` shell function (`common/zsh/functions/moshi`) creates
a project session with five windows (agent/review/tests/servers/misc)
when starting fresh on a new directory. iPhone selector reads
`tmux list-sessions` so all sessions show up regardless of who created
them — pick `main`, `mobile`, or any project session.

## MOSHI_CLIENT signal

Moshi iOS exports `MOSHI_CLIENT=1` (Settings -> Integrations -> Export
ENV). `common/tmux/tmux.conf` propagates it via `update-environment`
and adapts the status bar so swipe-to-change-window works on the
phone. `hook-runner.sh` queries attached clients for this var to gate
push notifications.

## See also

- [docs/ssh-mosh-setup-guide.md](../../docs/ssh-mosh-setup-guide.md) — host setup
- upstream: <https://github.com/rjyo/moshi-hooks>
