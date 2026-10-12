#!/bin/zsh

emulate -LR zsh
setopt errexit nounset pipefail

SCRIPT_DIR="${0:A:h}"
SUBJECT="${SCRIPT_DIR:h}/bring-app-to-workspace.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fake_aero="$tmpdir/aerospace"
calls_file="$tmpdir/calls.log"
windows_file="$tmpdir/windows.tsv"
focused_id_file="$tmpdir/focused-id"
focused_workspace_file="$tmpdir/focused-workspace"

cat > "$fake_aero" <<'FAKE_AERO'
#!/bin/zsh

emulate -LR zsh
setopt errexit nounset pipefail

cmd="$1"
shift

case "$cmd" in
	list-windows)
		local scope="" format=""
		while (( $# > 0 )); do
			case "$1" in
				--all|--focused)
					scope="$1"
					shift
					;;
				--format)
					format="$2"
					shift 2
					;;
				*)
					shift
					;;
			esac
		done

		if [[ "$scope" == "--all" ]]; then
			cat "$FAKE_WINDOWS"
		elif [[ "$format" == *workspace* ]]; then
			cat "$FAKE_FOCUSED_WORKSPACE"
		else
			cat "$FAKE_FOCUSED_ID"
		fi
		;;
	move-node-to-workspace)
		local wid="" workspace=""
		while (( $# > 0 )); do
			case "$1" in
				--window-id)
					wid="$2"
					shift 2
					;;
				*)
					workspace="$1"
					shift
					;;
			esac
		done
		print -r -- "move-node	$wid	$workspace" >> "$FAKE_CALLS"
		;;
	focus)
		local wid=""
		while (( $# > 0 )); do
			case "$1" in
				--window-id)
					wid="$2"
					shift 2
					;;
				*)
					shift
					;;
			esac
		done
		print -r -- "focus	$wid" >> "$FAKE_CALLS"
		;;
	layout)
		local wid="" layout=""
		while (( $# > 0 )); do
			case "$1" in
				--window-id)
					wid="$2"
					shift 2
					;;
				*)
					layout="$1"
					shift
					;;
			esac
		done
		print -r -- "layout	$wid	$layout" >> "$FAKE_CALLS"
		;;
	flatten-workspace-tree)
		local workspace=""
		while (( $# > 0 )); do
			case "$1" in
				--workspace)
					workspace="$2"
					shift 2
					;;
				*)
					shift
					;;
			esac
		done
		print -r -- "flatten	$workspace" >> "$FAKE_CALLS"
		;;
	*)
		print -u2 -- "unexpected aerospace command: $cmd $*"
		exit 64
		;;
esac
FAKE_AERO
chmod +x "$fake_aero"

export AERO="$fake_aero"
export FAKE_WINDOWS="$windows_file"
export FAKE_FOCUSED_ID="$focused_id_file"
export FAKE_FOCUSED_WORKSPACE="$focused_workspace_file"
export FAKE_CALLS="$calls_file"

reset_calls() {
	: > "$calls_file"
}

assert_called() {
	local expected="$1"

	if ! grep -Fxq "$expected" "$calls_file"; then
		print -u2 -- "Expected call not found:"
		print -u2 -- "$expected"
		print -u2 -- "Calls were:"
		cat "$calls_file" >&2
		exit 1
	fi
}

test_tiles_brought_safari_window() {
	reset_calls
	print -- "500" > "$focused_id_file"
	print -- "9" > "$focused_workspace_file"
	cat > "$windows_file" <<'WINDOWS'
301	Safari
302	Safari
500	Ghostty
WINDOWS

	"$SUBJECT" "Safari" "Safari"

	assert_called $'move-node	301	9'
	assert_called $'layout	301	tiling'
	assert_called $'focus	301'
	assert_called $'flatten	9'
}

test_tiles_next_safari_window_when_current_safari_is_focused() {
	reset_calls
	print -- "301" > "$focused_id_file"
	print -- "9" > "$focused_workspace_file"
	cat > "$windows_file" <<'WINDOWS'
301	Safari
302	Safari
500	Ghostty
WINDOWS

	"$SUBJECT" "Safari" "Safari"

	assert_called $'move-node	302	9'
	assert_called $'layout	302	tiling'
	assert_called $'focus	302'
	assert_called $'flatten	9'
}

test_tiles_brought_safari_window
test_tiles_next_safari_window_when_current_safari_is_focused

print -- "bring-app-to-workspace tests passed"
