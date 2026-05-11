#!/bin/zsh
# Deterministically re-bucket AeroSpace windows into numeric workspaces.

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
	print -u2 "resort-windows: aerospace binary not found"
	exit 1
fi

unminimize_all_windows() {
	[[ "${UNMINIMIZE_FIRST:-0}" == "0" ]] && return 0
	command -v osascript >/dev/null 2>&1 || return 0

	/usr/bin/osascript >/dev/null 2>&1 <<'APPLESCRIPT' || true
tell application "System Events"
    repeat with appProcess in application processes
        repeat with appWindow in windows of appProcess
            try
                if value of attribute "AXMinimized" of appWindow then
                    set value of attribute "AXMinimized" of appWindow to false
                end if
            end try
        end repeat
    end repeat
end tell
APPLESCRIPT

	sleep 0.2
	unminimized_first=1
}

unminimized_first=0
unminimize_all_windows

typeset -A APP_SLOT=(
	"Microsoft Outlook" 1
	Outlook 1
	"Microsoft Teams" 2
	Messages 2
	Obsidian 3
	"Open WebUI" 4
	"Open WebUI.app" 4
)

OTHER_SLOT="5"
MINIMIZED_SLOT="6"
DYNAMIC_START="7"
typeset -A TOUCHED_WORKSPACES=()

mark_workspace_touched() {
	local workspace="$1"
	[[ -n "$workspace" ]] && TOUCHED_WORKSPACES[$workspace]=1
}

flatten_touched_workspaces() {
	local workspace

	for workspace in ${(kon)TOUCHED_WORKSPACES}; do
		"$AERO" flatten-workspace-tree --workspace "$workspace" >/dev/null 2>&1 || true
	done
}

move_window() {
	local wid="$1"
	local target="$2"
	local current="$3"

	[[ -z "$wid" || -z "$target" ]] && return 0
	mark_workspace_touched "$target"

	if [[ "$current" == "$target" ]]; then
		return 0
	fi

	if ! "$AERO" move-node-to-workspace --window-id "$wid" "$target" >/dev/null 2>&1; then
		print -u2 "resort-windows: failed to move window $wid to workspace $target"
		return 0
	fi
}

detect_monitors() {
	local record id name is_main
	typeset -g builtin_monitor=""
	typeset -g external_monitor=""
	typeset -g main_monitor=""

	for record in "${(@f)$($AERO list-monitors --format "%{monitor-id}%{tab}%{monitor-name}%{tab}%{monitor-is-main}" 2>/dev/null)}"; do
		IFS=$'\t' read -r id name is_main <<< "$record"
		[[ -z "$id" ]] && continue

		if [[ "$is_main" == "true" ]]; then
			main_monitor="$id"
		fi

		if [[ "${name:l}" == *built-in* ]]; then
			builtin_monitor="$id"
		elif [[ -z "$external_monitor" ]]; then
			external_monitor="$id"
		fi
	done

	if [[ -z "$builtin_monitor" ]]; then
		builtin_monitor="$main_monitor"
	fi
}

move_workspace_to_monitor() {
	local workspace="$1"
	local monitor="$2"

	[[ -z "$workspace" || -z "$monitor" ]] && return 0
	"$AERO" move-workspace-to-monitor --workspace "$workspace" "$monitor" >/dev/null 2>&1 || true
}

route_workspaces_to_monitors() {
	local workspace

	detect_monitors
	[[ -z "$builtin_monitor" || -z "$external_monitor" ]] && return 0

	for workspace in {1..6}; do
		move_workspace_to_monitor "$workspace" "$builtin_monitor"
	done

	for (( workspace = DYNAMIC_START; workspace < next_dynamic_workspace; workspace++ )); do
		move_workspace_to_monitor "$workspace" "$external_monitor"
	done
}

load_windows() {
	windows=("${(@f)$($AERO list-windows --all --format "%{window-id}%{tab}%{app-name}%{tab}%{workspace}%{tab}%{monitor-id}%{tab}%{window-title}" 2>/dev/null)}")
}

windows_have_app() {
	local expected="$1"
	local record _wid app _old_workspace _monitor _title

	for record in "${windows[@]}"; do
		IFS=$'\t' read -r _wid app _old_workspace _monitor _title <<< "$record"
		[[ "$app" == "$expected" ]] && return 0
	done

	return 1
}

ensure_safari_for_ghostty() {
	windows_have_app Ghostty || return 0
	windows_have_app Safari && return 0

	open -a "Safari" >/dev/null 2>&1 || true
	sleep 1
	load_windows
}

is_safari() {
	[[ "$1" == "Safari" ]]
}

is_code() {
	[[ "$1" == "Code" || "$1" == "Visual Studio Code" ]]
}

is_ghostty() {
	[[ "$1" == "Ghostty" ]]
}

is_minimized() {
	local app="$1"
	local title="$2"

	[[ "${CHECK_MINIMIZED:-0}" != "1" ]] && return 1
	[[ -z "$app" || -z "$title" ]] && return 1
	command -v osascript >/dev/null 2>&1 || return 1

	local result
	result="$(/usr/bin/osascript - "$app" "$title" 2>/dev/null <<'APPLESCRIPT'
on run argv
    set appName to item 1 of argv
    set windowTitle to item 2 of argv

    tell application "System Events"
        if not (exists process appName) then return "false"

        tell process appName
            repeat with candidateWindow in windows
                try
                    if (name of candidateWindow as text) is windowTitle then
                        try
                            if value of attribute "AXMinimized" of candidateWindow then return "true"
                        end try
                    end if
                end try
            end repeat
        end tell
    end tell

    return "false"
end run
APPLESCRIPT
)"

	[[ "$result" == "true" ]]
}

read_record() {
	local record="$1"
	IFS=$'\t' read -r wid app old_workspace monitor title <<< "$record"
}

process_fixed() {
	local record wid app old_workspace monitor title target slot

	for record in "$@"; do
		read_record "$record"
		slot="${APP_SLOT[$app]-}"
		[[ -z "$slot" ]] && continue
		move_window "$wid" "$slot" "$old_workspace"
	done
}

process_bucket() {
	local slot="$1"
	shift

	local record wid app old_workspace monitor title target
	for record in "$@"; do
		read_record "$record"
		move_window "$wid" "$slot" "$old_workspace"
	done
}

move_record_to_workspace() {
	local record="$1"
	local workspace="$2"
	local wid app old_workspace monitor title

	read_record "$record"
	move_window "$wid" "$workspace" "$old_workspace"
}

process_external_pairs() {
	local workspace="$DYNAMIC_START"
	local count=0
	local i record
	typeset -a external_records

	if (( ${#ghostty_records[@]} > 0 )); then
		move_record_to_workspace "${ghostty_records[1]}" "$workspace"
		if (( ${#safari_records[@]} > 0 )); then
			move_record_to_workspace "${safari_records[1]}" "$workspace"
		fi
		workspace=$(( workspace + 1 ))
	fi

	for (( i = 2; i <= ${#ghostty_records[@]}; i++ )); do
		external_records+=("${ghostty_records[$i]}")
	done

	for (( i = 1; i <= ${#safari_records[@]}; i++ )); do
		if (( ${#ghostty_records[@]} > 0 && i == 1 )); then
			continue
		fi
		external_records+=("${safari_records[$i]}")
	done

	for record in "${code_records[@]}"; do
		external_records+=("$record")
	done

	for record in "${external_records[@]}"; do
		move_record_to_workspace "$record" "$workspace"
		count=$(( count + 1 ))
		if (( count == 2 )); then
			workspace=$(( workspace + 1 ))
			count=0
		fi
	done

	if (( count > 0 )); then
		workspace=$(( workspace + 1 ))
	fi

	next_dynamic_workspace="$workspace"
}

typeset -a minimized_records fixed_records other_records ghostty_records safari_records code_records
typeset -a windows
next_dynamic_workspace="$DYNAMIC_START"

load_windows
ensure_safari_for_ghostty

if (( ${#windows[@]} == 0 )); then
	exit 0
fi

for record in "${windows[@]}"; do
	read_record "$record"
	[[ -z "$wid" || -z "$app" ]] && continue

	if (( ! unminimized_first )) && is_minimized "$app" "$title"; then
		minimized_records+=("$record")
	elif is_ghostty "$app"; then
		ghostty_records+=("$record")
	elif is_safari "$app"; then
		safari_records+=("$record")
	elif is_code "$app"; then
		code_records+=("$record")
	elif [[ -n "${APP_SLOT[$app]-}" ]]; then
		fixed_records+=("$record")
	else
		other_records+=("$record")
	fi
done

process_fixed "${fixed_records[@]}"
process_bucket "$OTHER_SLOT" "${other_records[@]}"
process_bucket "$MINIMIZED_SLOT" "${minimized_records[@]}"
process_external_pairs
route_workspaces_to_monitors
flatten_touched_workspaces
