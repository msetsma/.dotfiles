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

typeset -A BUILTIN_APP=(
	Hermes 1
	"Microsoft Outlook" 1
	Outlook 1
	"Microsoft Teams" 1
	Messages 1
	Obsidian 1
	"Open WebUI" 1
	"Open WebUI.app" 1
)

WINDOWS_PER_WORKSPACE=2
HORIZONTAL_LAYOUT="h_tiles"
VERTICAL_LAYOUT="v_tiles"
typeset -a SINGLE_MONITOR_APP_ORDER=(
	Hermes
	"Microsoft Outlook"
	"Microsoft Teams"
	Messages
	Obsidian
	"Open WebUI"
	Ghostty
	Safari
	Code
)
typeset -A TOUCHED_WORKSPACES=()
typeset -A WORKSPACE_SAMPLE_WINDOW=()
typeset -A WORKSPACE_LAYOUT=()
typeset -A WORKSPACE_MONITOR=()

mark_workspace_touched() {
	local workspace="$1"
	[[ -n "$workspace" ]] && TOUCHED_WORKSPACES[$workspace]=1
}

remember_workspace_window() {
	local workspace="$1"
	local wid="$2"

	[[ -z "$workspace" || -z "$wid" ]] && return 0
	if [[ -z "${WORKSPACE_SAMPLE_WINDOW[$workspace]-}" ]]; then
		WORKSPACE_SAMPLE_WINDOW[$workspace]="$wid"
	fi
}

set_workspace_layout() {
	local workspace="$1"
	local layout="$2"

	[[ -z "$workspace" || -z "$layout" ]] && return 0
	WORKSPACE_LAYOUT[$workspace]="$layout"
}

set_workspace_monitor() {
	local workspace="$1"
	local monitor="$2"

	[[ -z "$workspace" || -z "$monitor" ]] && return 0
	WORKSPACE_MONITOR[$workspace]="$monitor"
}

apply_workspace_layouts() {
	local workspace wid layout

	for workspace in ${(kon)WORKSPACE_LAYOUT}; do
		wid="${WORKSPACE_SAMPLE_WINDOW[$workspace]-}"
		layout="${WORKSPACE_LAYOUT[$workspace]-}"
		[[ -z "$wid" || -z "$layout" ]] && continue
		"$AERO" layout --window-id "$wid" "$layout" >/dev/null 2>&1 || true
	done
}

flatten_touched_workspaces() {
	local workspace

	for workspace in ${(kon)TOUCHED_WORKSPACES}; do
		"$AERO" flatten-workspace-tree --workspace "$workspace" >/dev/null 2>&1 || true
	done
}

ensure_window_tiling() {
	local wid="$1"

	[[ -z "$wid" ]] && return 0
	"$AERO" layout --window-id "$wid" tiling >/dev/null 2>&1 || true
}

move_window() {
	local wid="$1"
	local target="$2"
	local current="$3"

	[[ -z "$wid" || -z "$target" ]] && return 0
	mark_workspace_touched "$target"

	if [[ "$current" == "$target" ]]; then
		remember_workspace_window "$target" "$wid"
		ensure_window_tiling "$wid"
		return 0
	fi

	if ! "$AERO" move-node-to-workspace --window-id "$wid" "$target" >/dev/null 2>&1; then
		print -u2 "resort-windows: failed to move window $wid to workspace $target"
		return 0
	fi
	remember_workspace_window "$target" "$wid"
	ensure_window_tiling "$wid"
}

detect_monitors() {
	local record id name is_main
	typeset -a external_monitors
	typeset -g builtin_monitor=""
	typeset -g external_monitor=""
	typeset -g reference_monitor=""
	typeset -g main_monitor=""
	typeset -g ultrawide_monitor=""

	for record in "${(@f)$($AERO list-monitors --format "%{monitor-id}%{tab}%{monitor-name}%{tab}%{monitor-is-main}" 2>/dev/null)}"; do
		IFS=$'\t' read -r id name is_main <<< "$record"
		[[ -z "$id" ]] && continue

		if [[ "$is_main" == "true" ]]; then
			main_monitor="$id"
		fi

		if [[ "${name:l}" == *built-in* ]]; then
			builtin_monitor="$id"
		else
			external_monitors+=("$id")
			if [[ -z "$external_monitor" ]]; then
				external_monitor="$id"
			fi
			if [[ "$is_main" == "true" ]]; then
				external_monitor="$id"
			fi
			if [[ "${name:l}" == *u3415w* ]]; then
				# Ultrawide: always the horizontal (side-by-side) display.
				ultrawide_monitor="$id"
			elif [[ "${name:l}" == *dell* ]]; then
				# Any other Dell: vertical-stacking reference display.
				reference_monitor="$id"
			fi
		fi
	done

	if [[ -z "$builtin_monitor" ]]; then
		builtin_monitor="$main_monitor"
	fi

	if [[ -n "$ultrawide_monitor" ]]; then
		external_monitor="$ultrawide_monitor"
	fi

	if (( ${#external_monitors[@]} < 2 )); then
		reference_monitor=""
	elif [[ -z "$reference_monitor" ]]; then
		for id in "${external_monitors[@]}"; do
			if [[ "$id" != "$external_monitor" ]]; then
				reference_monitor="$id"
				break
			fi
		done
	elif [[ "$reference_monitor" == "$external_monitor" ]]; then
		for id in "${external_monitors[@]}"; do
			if [[ "$id" != "$reference_monitor" ]]; then
				external_monitor="$id"
				break
			fi
		done
	fi
}

move_workspace_to_monitor() {
	local workspace="$1"
	local monitor="$2"

	[[ -z "$workspace" || -z "$monitor" ]] && return 0
	"$AERO" move-workspace-to-monitor --workspace "$workspace" "$monitor" >/dev/null 2>&1 || true
}

route_workspaces_to_monitors() {
	local workspace monitor

	detect_monitors

	for workspace in ${(kon)WORKSPACE_MONITOR}; do
		monitor="${WORKSPACE_MONITOR[$workspace]-}"
		move_workspace_to_monitor "$workspace" "$monitor"
	done
}

has_external_monitor() {
	detect_monitors
	[[ -n "$external_monitor" ]]
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

app_group_key() {
	local app="$1"

	case "$app" in
		Outlook|"Microsoft Outlook")
			print -- "Microsoft Outlook"
			;;
		"Open WebUI.app"|"Open WebUI")
			print -- "Open WebUI"
			;;
		"Visual Studio Code"|Code)
			print -- "Code"
			;;
		*)
			print -- "$app"
			;;
	esac
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

move_record_to_workspace() {
	local record="$1"
	local workspace="$2"
	local wid app old_workspace monitor title

	read_record "$record"
	move_window "$wid" "$workspace" "$old_workspace"
}

assign_records_to_compact_workspaces() {
	local monitor="$1"
	local layout="$2"
	shift 2

	local record count=0
	for record in "$@"; do
		set_workspace_layout "$next_workspace" "$layout"
		set_workspace_monitor "$next_workspace" "$monitor"
		move_record_to_workspace "$record" "$next_workspace"
		count=$(( count + 1 ))
		if (( count == WINDOWS_PER_WORKSPACE )); then
			next_workspace=$(( next_workspace + 1 ))
			count=0
		fi
	done

	if (( count > 0 )); then
		next_workspace=$(( next_workspace + 1 ))
	fi
}

process_external_pairs() {
	local i record
	typeset -a first_external_records external_records reference_records

	if (( ${#ghostty_records[@]} > 0 )); then
		first_external_records+=("${ghostty_records[1]}")
		if [[ -z "$reference_monitor" ]] && (( ${#safari_records[@]} > 0 )); then
			first_external_records+=("${safari_records[1]}")
		fi
	fi

	for (( i = 2; i <= ${#ghostty_records[@]}; i++ )); do
		external_records+=("${ghostty_records[$i]}")
	done

	for (( i = 1; i <= ${#safari_records[@]}; i++ )); do
		if [[ -n "$reference_monitor" ]]; then
			reference_records+=("${safari_records[$i]}")
			continue
		fi
		if (( ${#ghostty_records[@]} > 0 && i == 1 )); then
			continue
		fi
		external_records+=("${safari_records[$i]}")
	done

	for record in "${code_records[@]}"; do
		external_records+=("$record")
	done

	assign_records_to_compact_workspaces "$external_monitor" "$HORIZONTAL_LAYOUT" "${first_external_records[@]}"
	assign_records_to_compact_workspaces "$external_monitor" "$HORIZONTAL_LAYOUT" "${external_records[@]}"
	assign_records_to_compact_workspaces "$reference_monitor" "$VERTICAL_LAYOUT" "${reference_records[@]}"
}

process_single_monitor_app_workspaces() {
	local record wid app old_workspace monitor title key workspace count
	typeset -A seen_group completed_group
	typeset -a groups ordered_groups

	for record in "${windows[@]}"; do
		read_record "$record"
		[[ -z "$wid" || -z "$app" ]] && continue

		key="$(app_group_key "$app")"
		if [[ -z "${seen_group[$key]-}" ]]; then
			seen_group[$key]=1
			groups+=("$key")
		fi
	done

	for key in "${SINGLE_MONITOR_APP_ORDER[@]}"; do
		if [[ -n "${seen_group[$key]-}" ]]; then
			ordered_groups+=("$key")
			completed_group[$key]=1
		fi
	done

	for key in "${(@o)groups}"; do
		[[ -n "${completed_group[$key]-}" ]] && continue
		ordered_groups+=("$key")
	done

	workspace=1
	for key in "${ordered_groups[@]}"; do
		count=0
		for record in "${windows[@]}"; do
			read_record "$record"
			[[ -z "$wid" || -z "$app" ]] && continue
			[[ "$(app_group_key "$app")" != "$key" ]] && continue

			set_workspace_layout "$workspace" "$HORIZONTAL_LAYOUT"
			move_window "$wid" "$workspace" "$old_workspace"
			count=$(( count + 1 ))
			if (( count == WINDOWS_PER_WORKSPACE )); then
				workspace=$(( workspace + 1 ))
				count=0
			fi
		done

		if (( count > 0 )); then
			workspace=$(( workspace + 1 ))
		fi
	done
}

typeset -a minimized_records fixed_records other_records ghostty_records safari_records code_records
typeset -a windows
next_workspace=1

load_windows
if has_external_monitor; then
	external_monitor_attached=1
	ensure_safari_for_ghostty
else
	external_monitor_attached=0
fi

if (( ${#windows[@]} == 0 )); then
	exit 0
fi

if (( ! external_monitor_attached )); then
	process_single_monitor_app_workspaces
	flatten_touched_workspaces
	apply_workspace_layouts
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
	elif [[ -n "${BUILTIN_APP[$app]-}" ]]; then
		fixed_records+=("$record")
	else
		other_records+=("$record")
	fi
done

assign_records_to_compact_workspaces "$builtin_monitor" "$HORIZONTAL_LAYOUT" "${fixed_records[@]}"
assign_records_to_compact_workspaces "$builtin_monitor" "$HORIZONTAL_LAYOUT" "${other_records[@]}"
assign_records_to_compact_workspaces "$builtin_monitor" "$HORIZONTAL_LAYOUT" "${minimized_records[@]}"
process_external_pairs
route_workspaces_to_monitors
flatten_touched_workspaces
apply_workspace_layouts
