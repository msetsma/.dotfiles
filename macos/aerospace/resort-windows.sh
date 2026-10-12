#!/bin/zsh
# Deterministically re-bucket AeroSpace windows into role-based workspaces.
#
# Placement:
#   * Main external display  -> work apps (terminal, browser, editors), 2/workspace
#   * Vertical reference     -> notes / AI, stacked, 2/workspace
#   * Built-in display       -> communications + overflow, 1/workspace
#   * No external display    -> everything packs work-first, 2/workspace
#
# Reorder apps by editing the *_APP_ORDER arrays below.

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

## Tunables --------------------------------------------------------------------

# Windows sharing a workspace before spilling into the next workspace.
WINDOWS_PER_WORKSPACE_EXTERNAL=2
WINDOWS_PER_WORKSPACE_REFERENCE=2
WINDOWS_PER_WORKSPACE_BUILTIN=1
WINDOWS_PER_WORKSPACE_SINGLE=2

HORIZONTAL_LAYOUT="h_tiles"
VERTICAL_LAYOUT="v_tiles"

# Main external display (landscape): terminal + browser first, then editors.
typeset -a EXTERNAL_APP_ORDER=(
	Ghostty
	Safari
	Code
	"T3 Code (Alpha)"
)

# Vertical reference display: notes + AI.
typeset -a REFERENCE_APP_ORDER=(
	Obsidian
	Claude
)

# Built-in display: communications, one app per workspace.
typeset -a BUILTIN_APP_ORDER=(
	"Microsoft Outlook"
	"Microsoft Teams"
	Messages
)

# Single-display fallback: work-first.
typeset -a SINGLE_MONITOR_APP_ORDER=(
	Code
	"T3 Code (Alpha)"
	Ghostty
	Safari
	Obsidian
	Claude
	"Microsoft Outlook"
	"Microsoft Teams"
	Messages
)

typeset -A EXTERNAL_KEYS=()
typeset -A REFERENCE_KEYS=()
typeset -A BUILTIN_KEYS=()
typeset -A SINGLE_KEYS=()
for _key in "${EXTERNAL_APP_ORDER[@]}"; do EXTERNAL_KEYS[$_key]=1; done
for _key in "${REFERENCE_APP_ORDER[@]}"; do REFERENCE_KEYS[$_key]=1; done
for _key in "${BUILTIN_APP_ORDER[@]}"; do BUILTIN_KEYS[$_key]=1; done
for _key in "${SINGLE_MONITOR_APP_ORDER[@]}"; do SINGLE_KEYS[$_key]=1; done
unset _key

## Window / workspace state ----------------------------------------------------

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

typeset -a windows=()
typeset -a present_keys=()
typeset -A present_key_set=()
typeset -A TOUCHED_WORKSPACES=()
typeset -A WORKSPACE_SAMPLE_WINDOW=()
typeset -A WORKSPACE_LAYOUT=()
typeset -A WORKSPACE_MONITOR=()
next_workspace=1

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

## Grouping helpers ------------------------------------------------------------

app_group_key() {
	local app="$1"

	case "$app" in
		Outlook|"Microsoft Outlook")
			print -- "Microsoft Outlook"
			;;
		"Visual Studio Code"|Code)
			print -- "Code"
			;;
		*)
			print -- "$app"
			;;
	esac
}

is_ghostty() {
	[[ "$1" == "Ghostty" ]]
}

read_record() {
	local record="$1"
	IFS=$'\t' read -r wid app old_workspace monitor title <<< "$record"
}

collect_present_keys() {
	local record wid app key

	present_keys=()
	present_key_set=()

	for record in "${windows[@]}"; do
		read_record "$record"
		[[ -z "$wid" || -z "$app" ]] && continue
		key="$(app_group_key "$app")"
		[[ -n "${present_key_set[$key]-}" ]] && continue
		present_key_set[$key]=1
		present_keys+=("$key")
	done
}

# Print the present keys from a preferred order (read-only).
order_present() {
	local key

	for key in "$@"; do
		[[ -n "${present_key_set[$key]-}" ]] && print -- "$key"
	done
}

# Print every window whose group key is in the given list, in that order.
records_for_keys() {
	local key record wid app old_workspace monitor title

	for key in "$@"; do
		for record in "${windows[@]}"; do
			read_record "$record"
			[[ -z "$wid" || -z "$app" ]] && continue
			[[ "$(app_group_key "$app")" != "$key" ]] && continue
			print -r -- "$record"
		done
	done
}

## Moving ----------------------------------------------------------------------

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
	local per_ws="$3"
	shift 3

	local record count=0
	for record in "$@"; do
		[[ -z "$record" ]] && continue
		set_workspace_layout "$next_workspace" "$layout"
		set_workspace_monitor "$next_workspace" "$monitor"
		move_record_to_workspace "$record" "$next_workspace"
		count=$(( count + 1 ))
		if (( count >= per_ws )); then
			next_workspace=$(( next_workspace + 1 ))
			count=0
		fi
	done

	if (( count > 0 )); then
		next_workspace=$(( next_workspace + 1 ))
	fi
}

## Monitors --------------------------------------------------------------------

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

## Layout application ----------------------------------------------------------

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

## Placement strategies --------------------------------------------------------

process_single_monitor_app_workspaces() {
	local key
	typeset -a ordered_keys ordered_records

	ordered_keys=("${(@f)$(order_present "${SINGLE_MONITOR_APP_ORDER[@]}")}")
	for key in "${present_keys[@]}"; do
		[[ -n "${SINGLE_KEYS[$key]-}" ]] && continue
		ordered_keys+=("$key")
	done

	ordered_records=("${(@f)$(records_for_keys "${ordered_keys[@]}")}")
	assign_records_to_compact_workspaces "$builtin_monitor" "$HORIZONTAL_LAYOUT" "$WINDOWS_PER_WORKSPACE_SINGLE" "${ordered_records[@]}"
}

process_multi_monitor() {
	local key
	typeset -a external_keys reference_keys builtin_keys other_keys
	typeset -a external_records reference_records builtin_records

	external_keys=("${(@f)$(order_present "${EXTERNAL_APP_ORDER[@]}")}")
	reference_keys=("${(@f)$(order_present "${REFERENCE_APP_ORDER[@]}")}")
	builtin_keys=("${(@f)$(order_present "${BUILTIN_APP_ORDER[@]}")}")

	for key in "${present_keys[@]}"; do
		[[ -n "${EXTERNAL_KEYS[$key]-}${REFERENCE_KEYS[$key]-}${BUILTIN_KEYS[$key]-}" ]] && continue
		other_keys+=("$key")
	done

	# With no vertical reference display, notes/AI collapse onto the built-in.
	if [[ -z "$reference_monitor" ]]; then
		builtin_keys+=("${reference_keys[@]}")
		reference_keys=()
	fi

	builtin_keys+=("${other_keys[@]}")

	external_records=("${(@f)$(records_for_keys "${external_keys[@]}")}")
	builtin_records=("${(@f)$(records_for_keys "${builtin_keys[@]}")}")

	assign_records_to_compact_workspaces "$external_monitor" "$HORIZONTAL_LAYOUT" "$WINDOWS_PER_WORKSPACE_EXTERNAL" "${external_records[@]}"

	if [[ -n "$reference_monitor" ]]; then
		reference_records=("${(@f)$(records_for_keys "${reference_keys[@]}")}")
		assign_records_to_compact_workspaces "$reference_monitor" "$VERTICAL_LAYOUT" "$WINDOWS_PER_WORKSPACE_REFERENCE" "${reference_records[@]}"
	fi

	assign_records_to_compact_workspaces "$builtin_monitor" "$HORIZONTAL_LAYOUT" "$WINDOWS_PER_WORKSPACE_BUILTIN" "${builtin_records[@]}"
}

## Main ------------------------------------------------------------------------

load_windows
if (( ${#windows[@]} == 0 )); then
	exit 0
fi

collect_present_keys
detect_monitors

if [[ -z "$external_monitor" ]]; then
	process_single_monitor_app_workspaces
	flatten_touched_workspaces
	apply_workspace_layouts
	exit 0
fi

ensure_safari_for_ghostty
load_windows
collect_present_keys

process_multi_monitor
route_workspaces_to_monitors
flatten_touched_workspaces
apply_workspace_layouts