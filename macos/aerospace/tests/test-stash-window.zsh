#!/bin/zsh

emulate -LR zsh
setopt errexit nounset pipefail

SCRIPT_DIR="${0:A:h}"
SUBJECT="${SCRIPT_DIR:h}/stash-window.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fake_aero="$tmpdir/aerospace"
calls_file="$tmpdir/calls.log"

cat > "$fake_aero" <<'FAKE_AERO'
#!/bin/zsh

emulate -LR zsh
setopt errexit nounset pipefail

cmd="$1"
shift

case "$cmd" in
	list-windows)
		print -- "901"
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
export FAKE_CALLS="$calls_file"

: > "$calls_file"
"$SUBJECT"

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

assert_called $'move-node	901	6'
assert_called $'layout	901	tiling'
assert_called $'flatten	6'

print -- "stash-window tests passed"
