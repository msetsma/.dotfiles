#!/bin/zsh

emulate -LR zsh
setopt pipefail

APP_NAME="$1"
OPEN_TARGET="${2:-$APP_NAME}"
AERO="${AERO:-}"

if [[ -z "$APP_NAME" ]]; then
	print -u2 "focus-cycle: app name required"
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
	print -u2 "focus-cycle: aerospace binary not found"
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

for record in "${(@f)$("$AERO" list-windows --all --format "%{window-id}%{tab}%{app-name}" 2>/dev/null)}"; do
	IFS=$'\t' read -r wid app <<< "$record"
	[[ -z "$wid" || -z "$app" ]] && continue
	app_matches "$app" && WINDOW_IDS+=("$wid")
done

if (( ${#WINDOW_IDS[@]} == 0 )); then
	open_app
	exit 0
fi

FOCUSED="$("$AERO" list-windows --focused --format "%{window-id}" 2>/dev/null)"

COUNT=${#WINDOW_IDS[@]}

if (( COUNT == 1 )); then
	"$AERO" focus --window-id "${WINDOW_IDS[1]}"
	exit 0
fi

NEXT_INDEX=1
for (( i = 1; i <= COUNT; i++ )); do
	if [[ "${WINDOW_IDS[$i]}" == "$FOCUSED" ]]; then
		if (( i == COUNT )); then
			NEXT_INDEX=1
		else
			NEXT_INDEX=$(( i + 1 ))
		fi
		break
	fi
done

"$AERO" focus --window-id "${WINDOW_IDS[$NEXT_INDEX]}"
