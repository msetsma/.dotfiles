#!/bin/zsh

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
	print -u2 "move-window-to-empty-workspace: aerospace binary not found"
	exit 1
fi

focused="$("$AERO" list-windows --focused --format "%{window-id}" 2>/dev/null)"
[[ -z "$focused" ]] && exit 0

is_positive_integer() {
	[[ "$1" == <-> ]] && (( $1 > 0 ))
}

typeset -A occupied_workspaces empty_workspaces
max_workspace=0

track_workspace_number() {
	local workspace="$1"

	is_positive_integer "$workspace" || return 1
	(( workspace > max_workspace )) && max_workspace="$workspace"
	return 0
}

for workspace in "${(@f)$("$AERO" list-workspaces --all --format "%{workspace}" 2>/dev/null)}"; do
	if track_workspace_number "$workspace"; then
		occupied_workspaces[$workspace]=1
	fi
done

for monitor in "${(@f)$("$AERO" list-monitors --format "%{monitor-id}" 2>/dev/null)}"; do
	[[ -z "$monitor" ]] && continue
	for workspace in "${(@f)$("$AERO" list-workspaces --monitor "$monitor" --empty --format "%{workspace}" 2>/dev/null)}"; do
		if track_workspace_number "$workspace"; then
			empty_workspaces[$workspace]=1
		fi
	done
done

target=""
for (( workspace = 1; workspace <= max_workspace + 1; workspace++ )); do
	if [[ -n "${empty_workspaces[$workspace]}" || -z "${occupied_workspaces[$workspace]}" ]]; then
		target="$workspace"
		break
	fi
done

if [[ -z "$target" ]]; then
	print -u2 "move-window-to-empty-workspace: no target workspace found"
	exit 1
fi

"$AERO" move-node-to-workspace --window-id "$focused" "$target" >/dev/null 2>&1 || exit 1
"$AERO" layout --window-id "$focused" tiling >/dev/null 2>&1 || true
"$AERO" workspace "$target" >/dev/null 2>&1 || true
"$AERO" flatten-workspace-tree --workspace "$target" >/dev/null 2>&1 || true
