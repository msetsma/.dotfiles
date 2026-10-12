#!/bin/zsh

emulate -LR zsh
setopt pipefail

APP_NAME="$1"
OPEN_TARGET="${2:-$APP_NAME}"
AERO="${AERO:-}"

if [[ -z "$APP_NAME" ]]; then
	print -u2 "bring-app-to-workspace: app name required"
	exit 1
fi

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
	print -u2 "bring-app-to-workspace: aerospace binary not found"
	exit 1
fi

typeset -a APP_NAMES WINDOW_IDS
APP_NAMES=("$APP_NAME")
if (( $# > 2 )); then
	APP_NAMES+=("${@:3}")
fi

app_matches() {
	local candidate="$1"
	local expected

	for expected in "${APP_NAMES[@]}"; do
		[[ "$candidate" == "$expected" ]] && return 0
	done

	return 1
}

open_app() {
	if [[ "$OPEN_TARGET" == /* || "$OPEN_TARGET" == *.app ]]; then
		open "$OPEN_TARGET"
	else
		open -a "$OPEN_TARGET"
	fi
}

current_workspace() {
	local workspace

	workspace="$("$AERO" list-windows --focused --format "%{workspace}" 2>/dev/null)"
	if [[ -n "$workspace" ]]; then
		print -- "$workspace"
		return 0
	fi

	"$AERO" list-workspaces --focused 2>/dev/null
}

for record in "${(@f)$("$AERO" list-windows --all --format "%{window-id}%{tab}%{app-name}" 2>/dev/null)}"; do
	IFS=$'\t' read -r wid app <<< "$record"
	[[ -z "$wid" || -z "$app" ]] && continue
	app_matches "$app" && WINDOW_IDS+=("$wid")
done

if (( ${#WINDOW_IDS[@]} == 0 )); then
	open_app
	exit 0
fi

WORKSPACE="$(current_workspace)"
WORKSPACE="${${(f)WORKSPACE}[1]}"
if [[ -z "$WORKSPACE" ]]; then
	print -u2 "bring-app-to-workspace: focused workspace not found"
	exit 1
fi

FOCUSED="$("$AERO" list-windows --focused --format "%{window-id}" 2>/dev/null)"
COUNT=${#WINDOW_IDS[@]}

TARGET_INDEX=1
if (( COUNT > 1 )); then
	for (( i = 1; i <= COUNT; i++ )); do
		if [[ "${WINDOW_IDS[$i]}" == "$FOCUSED" ]]; then
			if (( i == COUNT )); then
				TARGET_INDEX=1
			else
				TARGET_INDEX=$(( i + 1 ))
			fi
			break
		fi
	done
fi

TARGET_WINDOW="${WINDOW_IDS[$TARGET_INDEX]}"

"$AERO" move-node-to-workspace --window-id "$TARGET_WINDOW" "$WORKSPACE" >/dev/null 2>&1 || exit 1
"$AERO" layout --window-id "$TARGET_WINDOW" tiling >/dev/null 2>&1 || true
"$AERO" focus --window-id "$TARGET_WINDOW" >/dev/null 2>&1 || true
"$AERO" flatten-workspace-tree --workspace "$WORKSPACE" >/dev/null 2>&1 || true
