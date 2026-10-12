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
	UNMINIMIZE_FIRST=0 "$SUBJECT"
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

test_single_monitor_packs_work_first() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	true
MONITORS
	cat > "$windows_file" <<'WINDOWS'
101	Code	9	1	repo-one
102	Ghostty	9	1	shell
103	Safari	9	1	docs
104	T3 Code (Alpha)	9	1	t3
105	Obsidian	9	1	notes
106	Claude	9	1	chat
107	Microsoft Outlook	9	1	inbox
108	Microsoft Teams	9	1	teams
109	Messages	9	1	im
WINDOWS

	run_subject

	assert_called $'move-node	101	1'
	assert_called $'move-node	104	1'
	assert_called $'move-node	102	2'
	assert_called $'move-node	103	2'
	assert_called $'move-node	105	3'
	assert_called $'move-node	106	3'
	assert_called $'move-node	107	4'
	assert_called $'move-node	108	4'
	assert_called $'move-node	109	5'
	assert_called $'layout	101	h_tiles'
	assert_called $'layout	102	h_tiles'
	assert_called $'layout	105	h_tiles'
	assert_called $'layout	107	h_tiles'
	assert_called $'layout	109	h_tiles'
	assert_not_called $'move-workspace	1	1'
}

test_single_monitor_skips_windows_already_in_place() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	true
MONITORS
	cat > "$windows_file" <<'WINDOWS'
801	Code	1	1	repo-one
WINDOWS

	run_subject

	assert_not_called $'move-node	801	1'
	assert_called $'layout	801	tiling'
	assert_called $'layout	801	h_tiles'
}

test_two_monitors_routes_work_external_comms_builtin() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
MONITORS
	cat > "$windows_file" <<'WINDOWS'
201	Code	9	1	repo
202	Microsoft Outlook	9	1	inbox
WINDOWS

	run_subject

	assert_called $'move-node	201	1'
	assert_called $'move-node	202	2'
	assert_called $'layout	201	h_tiles'
	assert_called $'layout	202	h_tiles'
	assert_called $'move-workspace	1	2'
	assert_called $'move-workspace	2	1'
}

test_three_monitors_places_notes_on_reference() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
3	DELL U2422HE	false
MONITORS
	cat > "$windows_file" <<'WINDOWS'
301	Ghostty	9	1	shell
302	Safari	9	1	docs
303	Code	9	1	repo
304	Obsidian	9	1	notes
305	Claude	9	1	chat
306	Microsoft Outlook	9	1	inbox
307	Microsoft Teams	9	1	teams
308	Messages	9	1	im
WINDOWS

	run_subject

	assert_called $'move-node	301	1'
	assert_called $'move-node	302	1'
	assert_called $'move-node	303	2'
	assert_called $'move-node	304	3'
	assert_called $'move-node	305	3'
	assert_called $'move-node	306	4'
	assert_called $'move-node	307	5'
	assert_called $'move-node	308	6'
	assert_called $'layout	301	h_tiles'
	assert_called $'layout	303	h_tiles'
	assert_called $'layout	304	v_tiles'
	assert_called $'layout	306	h_tiles'
	assert_called $'move-workspace	1	2'
	assert_called $'move-workspace	2	2'
	assert_called $'move-workspace	3	3'
	assert_called $'move-workspace	4	1'
	assert_called $'move-workspace	5	1'
	assert_called $'move-workspace	6	1'
}

test_external_splits_after_two_windows() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
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
	assert_called $'layout	401	h_tiles'
	assert_called $'layout	403	h_tiles'
	assert_called $'layout	405	h_tiles'
	assert_called $'move-workspace	1	2'
	assert_called $'move-workspace	2	2'
	assert_called $'move-workspace	3	2'
}

test_builtin_gets_one_window_per_workspace() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
MONITORS
	cat > "$windows_file" <<'WINDOWS'
501	Microsoft Outlook	9	1	Inbox
502	Microsoft Outlook	9	1	Calendar
503	SomeRandomApp	9	1	Window
WINDOWS

	run_subject

	assert_called $'move-node	501	1'
	assert_called $'move-node	502	2'
	assert_called $'move-node	503	3'
	assert_called $'layout	501	h_tiles'
	assert_called $'layout	502	h_tiles'
	assert_called $'layout	503	h_tiles'
	assert_called $'move-workspace	1	1'
	assert_called $'move-workspace	2	1'
	assert_called $'move-workspace	3	1'
}

test_editors_pair_on_external() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
MONITORS
	cat > "$windows_file" <<'WINDOWS'
601	Code	9	1	repo
602	T3 Code (Alpha)	9	1	t3
WINDOWS

	run_subject

	assert_called $'move-node	601	1'
	assert_called $'move-node	602	1'
	assert_called $'layout	601	h_tiles'
	assert_called $'move-workspace	1	2'
}

test_notes_collapse_to_builtin_without_reference_monitor() {
	reset_calls
	cat > "$monitors_file" <<'MONITORS'
1	Built-in Retina Display	false
2	Gigabyte M32U	true
MONITORS
	cat > "$windows_file" <<'WINDOWS'
701	Obsidian	9	1	notes
702	Claude	9	1	chat
703	Ghostty	9	1	shell
704	Safari	9	1	docs
WINDOWS

	run_subject

	assert_called $'move-node	703	1'
	assert_called $'move-node	704	1'
	assert_called $'move-node	701	2'
	assert_called $'move-node	702	3'
	assert_called $'layout	703	h_tiles'
	assert_called $'layout	701	h_tiles'
	assert_called $'layout	702	h_tiles'
	assert_called $'move-workspace	1	2'
	assert_called $'move-workspace	2	1'
	assert_called $'move-workspace	3	1'
}

test_single_monitor_packs_work_first
test_single_monitor_skips_windows_already_in_place
test_two_monitors_routes_work_external_comms_builtin
test_three_monitors_places_notes_on_reference
test_external_splits_after_two_windows
test_builtin_gets_one_window_per_workspace
test_editors_pair_on_external
test_notes_collapse_to_builtin_without_reference_monitor

print -- "resort-windows tests passed"