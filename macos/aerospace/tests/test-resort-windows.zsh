#!/bin/zsh

emulate -LR zsh
setopt errexit nounset pipefail

SCRIPT_DIR="${0:A:h}"
SUBJECT="${SCRIPT_DIR:h}/resort-windows.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fake_aero="$tmpdir/aerospace"
calls_file="$tmpdir/calls.log"
monitors_file="$tmpdir/monitors.tsv"
windows_file="$tmpdir/windows.tsv"

cat > "$fake_aero" <<'FAKE_AERO'
#!/bin/zsh

emulate -LR zsh
setopt errexit nounset pipefail

cmd="$1"
shift

case "$cmd" in
	list-monitors)
		cat "$FAKE_MONITORS"
		;;
	list-windows)
		cat "$FAKE_WINDOWS"
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
	move-workspace-to-monitor)
		local workspace="" monitor=""
		while (( $# > 0 )); do
			case "$1" in
				--workspace)
					workspace="$2"
					shift 2
					;;
				*)
					monitor="$1"
					shift
					;;
			esac
		done
		print -r -- "move-workspace	$workspace	$monitor" >> "$FAKE_CALLS"
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
		;;
	*)
		print -u2 -- "unexpected aerospace command: $cmd $*"
		exit 64
		;;
esac
FAKE_AERO
chmod +x "$fake_aero"

export AERO="$fake_aero"
export FAKE_MONITORS="$monitors_file"
export FAKE_WINDOWS="$windows_file"
export FAKE_CALLS="$calls_file"

reset_calls() {
	: > "$calls_file"
}

run_subject() {
	UNMINIMIZE_FIRST=0 CHECK_MINIMIZED=0 "$SUBJECT"
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

assert_not_called() {
	local unexpected="$1"

	if grep -Fxq "$unexpected" "$calls_file"; then
		print -u2 -- "Unexpected call found:"
		print -u2 -- "$unexpected"
		print -u2 -- "Calls were:"
		cat "$calls_file" >&2
		exit 1
	fi
}

test_two_monitors_keeps_safari_with_ghostty_on_external() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
MONITORS
	cat > "$windows_file" <<'WINDOWS'
101	Ghostty	9	1	Ghostty
102	Safari	10	1	Reference
WINDOWS

	run_subject

	assert_called $'move-node	101	1'
	assert_called $'move-node	102	1'
	assert_called $'layout	102	tiling'
	assert_called $'layout	101	h_tiles'
	assert_called $'move-workspace	1	2'
}

test_two_monitors_tiles_safari_already_in_target_workspace() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
MONITORS
	cat > "$windows_file" <<'WINDOWS'
101	Ghostty	1	2	Ghostty
102	Safari	1	2	Reference
WINDOWS

	run_subject

	assert_called $'layout	102	tiling'
	assert_called $'layout	101	h_tiles'
	assert_not_called $'move-node	102	1'
}

test_three_monitors_routes_safari_to_dell_reference_monitor() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
3	DELL U2422HE	false
MONITORS
	cat > "$windows_file" <<'WINDOWS'
201	Ghostty	9	1	Ghostty
202	Safari	10	1	Reference
WINDOWS

	run_subject

	assert_called $'move-node	201	1'
	assert_called $'move-node	202	2'
	assert_called $'layout	202	tiling'
	assert_called $'layout	201	h_tiles'
	assert_called $'layout	202	v_tiles'
	assert_called $'move-workspace	1	2'
	assert_called $'move-workspace	2	3'
	assert_not_called $'move-node	202	1'
}

test_three_monitors_keeps_builtin_workspaces_horizontal() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
3	DELL U2422HE	false
MONITORS
	cat > "$windows_file" <<'WINDOWS'
301	Microsoft Outlook	1	1	Inbox
302	Ghostty	1	1	Ghostty
303	Safari	2	1	Reference
WINDOWS

	run_subject

	assert_called $'layout	301	h_tiles'
	assert_called $'layout	302	h_tiles'
	assert_called $'layout	303	v_tiles'
}

test_single_monitor_splits_app_windows_after_two_per_workspace() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	true
MONITORS
	cat > "$windows_file" <<'WINDOWS'
401	Code	9	1	repo-one
402	Code	9	1	repo-two
403	Code	9	1	repo-three
404	Code	9	1	repo-four
405	Code	9	1	repo-five
WINDOWS

	run_subject

	assert_called $'move-node	401	1'
	assert_called $'move-node	402	1'
	assert_called $'move-node	403	2'
	assert_called $'move-node	404	2'
	assert_called $'move-node	405	3'
}

test_external_monitor_splits_builtin_app_windows_after_two_per_workspace() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
MONITORS
	cat > "$windows_file" <<'WINDOWS'
501	Microsoft Outlook	9	1	Inbox
502	Microsoft Outlook	9	1	Calendar
503	Microsoft Outlook	9	1	Mail
504	Microsoft Outlook	9	1	Search
505	Microsoft Outlook	9	1	Archive
WINDOWS

	run_subject

	assert_called $'move-node	501	1'
	assert_called $'move-node	502	1'
	assert_called $'move-node	503	2'
	assert_called $'move-node	504	2'
	assert_called $'move-node	505	3'
	assert_called $'move-workspace	2	1'
	assert_called $'move-workspace	3	1'
}

test_external_monitor_starts_code_windows_at_first_workspace() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
MONITORS
	cat > "$windows_file" <<'WINDOWS'
701	Code	9	1	repo-one
702	Code	9	1	repo-two
703	Code	9	1	repo-three
704	Code	9	1	repo-four
705	Code	9	1	repo-five
WINDOWS

	run_subject

	assert_called $'move-node	701	1'
	assert_called $'move-node	702	1'
	assert_called $'move-node	703	2'
	assert_called $'move-node	704	2'
	assert_called $'move-node	705	3'
	assert_called $'move-workspace	1	2'
	assert_called $'move-workspace	2	2'
	assert_called $'move-workspace	3	2'
}

test_three_monitors_splits_reference_windows_after_two_per_workspace() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
3	DELL U2422HE	false
MONITORS
	cat > "$windows_file" <<'WINDOWS'
601	Safari	9	1	Docs one
602	Safari	9	1	Docs two
603	Safari	9	1	Docs three
604	Safari	9	1	Docs four
605	Safari	10	1	Docs five
WINDOWS

	run_subject

	assert_called $'move-node	601	1'
	assert_called $'move-node	602	1'
	assert_called $'move-node	603	2'
	assert_called $'move-node	604	2'
	assert_called $'move-node	605	3'
	assert_called $'move-workspace	1	3'
	assert_called $'move-workspace	2	3'
	assert_called $'move-workspace	3	3'
}

test_two_monitors_keeps_safari_with_ghostty_on_external
test_two_monitors_tiles_safari_already_in_target_workspace
test_three_monitors_routes_safari_to_dell_reference_monitor
test_three_monitors_keeps_builtin_workspaces_horizontal
test_single_monitor_splits_app_windows_after_two_per_workspace
test_external_monitor_splits_builtin_app_windows_after_two_per_workspace
test_external_monitor_starts_code_windows_at_first_workspace
test_three_monitors_splits_reference_windows_after_two_per_workspace

print -- "resort-windows tests passed"
