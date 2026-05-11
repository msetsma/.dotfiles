#!/bin/zsh
# AeroSpace-friendly replacement for macOS minimize.

emulate -LR zsh
setopt pipefail

AERO="${AERO:-}"
if [[ -z "$AERO" ]]; then
	for candidate in /opt/homebrew/bin/aerospace /Applications/AeroSpace.app/Contents/MacOS/AeroSpace; do
		if [[ -x "$candidate" ]]; then
			AERO="$candidate"
			break
		fi
	done
fi

if [[ -z "$AERO" ]] && command -v aerospace >/dev/null 2>&1; then
	AERO="$(command -v aerospace)"
fi

if [[ -z "$AERO" || ! -x "$AERO" ]]; then
	print -u2 "stash-window: aerospace binary not found"
	exit 1
fi

focused="$($AERO list-windows --focused --format "%{window-id}" 2>/dev/null)"
[[ -z "$focused" ]] && exit 0

wid="$focused"
[[ -z "$wid" ]] && exit 0

target="6"

"$AERO" move-node-to-workspace --window-id "$wid" "$target" >/dev/null 2>&1 || exit 0
"$AERO" flatten-workspace-tree --workspace "$target" >/dev/null 2>&1 || true
