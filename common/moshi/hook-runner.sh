#!/usr/bin/env bash
# moshi-hooks gated runner — fires push only when a Moshi client is attached
# to the current tmux server. Skips silently when developing locally.
#
# Wired from ~/.claude/settings.json hook commands.

set -u

# Skip when no tmux server running (Claude invoked outside tmux).
command -v tmux >/dev/null 2>&1 || exit 0
tmux info >/dev/null 2>&1 || exit 0

# Any attached client exporting MOSHI_CLIENT? grep -q . matches any non-empty
# line — `client_environment:VAR` returns empty string when unset.
attached="$(tmux list-clients -F '#{client_environment:MOSHI_CLIENT}' 2>/dev/null)"
echo "$attached" | grep -q . || exit 0

# bunx hits local bun cache when available — no network on hot path.
exec bunx moshi-hooks "$@"
