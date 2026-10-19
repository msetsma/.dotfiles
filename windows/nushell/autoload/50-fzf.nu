# fzf pickers that edit the command line: cmds, file insert, line helper.
# Bound to keys in 60-keybinds.nu; `cmds` also works when typed.

# Fuzzy search aliases, custom commands and most-used history; enter inserts, ctrl-y copies
def cmds [
    count: int = 75  # number of top history commands to include
]: nothing -> nothing {
    let aliases = scope aliases | select name expansion | rename name detail
    let commands = scope commands
        | where type == custom and not ($it.name starts-with "_")
        | select name description
        | rename name detail
    let top_history = history
        | get command
        | each { split row " " | first }
        | uniq --count
        | sort-by count --reverse
        | first $count
        | each {|h| {name: $h.value, detail: $"used ($h.count) times"} }

    let rows = $aliases | append $commands | append $top_history | uniq-by name
    let width = $rows | get name | str length | math max
    let out = $rows
        | each {|r| $"(ansi cyan_bold)($r.name | fill --width $width)(ansi reset)  (ansi dark_gray)($r.detail)(ansi reset)\t($r.name)" }
        | str join "\n"
        | ^fzf --ansi --prompt 'cmds > ' --header 'enter inserts / ctrl-y copies' --delimiter "\t" --with-nth 1 --accept-nth 2 --expect ctrl-y --height 70%
        | lines
    if ($out | length) < 2 { return }

    let pick = $out | get 1
    if ($out | first) == "ctrl-y" { $pick | copy } else { commandline edit --replace $pick }
}

# Insert fuzzy-picked file paths at the cursor (bat preview, ctrl-/ toggles it)
def _fzf-insert-file []: nothing -> nothing {
    let picks = ^fzf --multi --walker-skip .git,node_modules,target --preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'
        | lines
    if ($picks | is-empty) { return }
    commandline edit --insert ($picks | each { if ($in =~ '\s') { $"`($in)`" } else { $in } } | str join " ")
}

# Fuzzy menu of command-line actions (port of the zsh alt-h widget)
def _line-helper []: nothing -> nothing {
    let actions = {
        "copy line": {|| commandline | copy }
        "cut line": {|| commandline | copy; commandline edit --replace "" }
        "clear line": {|| commandline edit --replace "" }
        "jump to start": {|| commandline set-cursor 0 }
        "jump to end": {|| commandline set-cursor --end }
    }
    let pick = $actions | columns | str join "\n" | ^fzf --prompt 'line > ' --height 40% | str trim
    if ($pick | is-empty) { return }
    do ($actions | get $pick)
}
