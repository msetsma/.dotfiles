# General tools: copy, archive, rld, update, ruff helpers, emoji2ascii.

use std/clip

# Copy piped input to the clipboard (OSC 52, works over SSH too)
def copy []: any -> nothing {
    $in | into string | clip copy52
}

# Copy the eza tree of the current directory
def ltcopy []: nothing -> nothing {
    ^eza --tree | copy
}

# Fuzzy multi-select entries in the current dir and move them to ~/ARCHIVE
def archive []: nothing -> nothing {
    let archive_dir = $nu.home-dir | path join ARCHIVE
    mkdir $archive_dir

    let picks = ls --all | get name
        | str join "\n"
        | ^fzf --multi --prompt 'archive > ' --header 'tab: multi-select' --preview-window right:60%:wrap --preview 'bat --color=always --style=numbers {} 2>nul || eza --icons --tree --level=2 --color=always {}'
        | lines
    if ($picks | is-empty) { print "No items selected"; return }

    for item in $picks {
        mv $item $archive_dir
        print $"(ansi green)✓(ansi reset) Archived: (ansi cyan)($item)(ansi reset)"
    }
    print $"\n($picks | length) items moved to (ansi cyan)($archive_dir)(ansi reset)"
}

# Reload the shell; optionally redeploy dotfiles or regenerate tool init files
def rld [
    --deploy  # run dotter first
    --regen   # regenerate starship/zoxide/carapace/vivid init files
]: nothing -> nothing {
    if $deploy {
        print "deploying dotfiles..."
        do { cd ($nu.home-dir | path join .dotfiles); ^dotter deploy }
    }
    if $regen {
        let vendor_dir = $nu.vendor-autoload-dirs | last
        [starship zoxide carapace vivid] | each {|t| $vendor_dir | path join $"($t).nu" } | where { path exists } | each { rm $in } | ignore
    }
    print "Reloading nu..."
    exec $nu.current-exe
}

# Check package managers for updates, then optionally apply them
def update []: nothing -> nothing {
    def count-lines []: string -> int { lines | where { str trim | is-not-empty } | length }

    # check: closure returning the outdated count, or null when it cannot tell
    let managers = [
        {
            name: "Scoop", bin: "scoop"
            check: {|| ^scoop status | complete | get stdout | ansi strip | lines | skip until { str starts-with "----" } | skip 1 | str join "\n" | count-lines }
            # nu itself is skipped while running (exe is locked); update it from pwsh
            apply: {|| ^scoop update; ^scoop update --all; ^scoop cleanup --all }
        }
        {
            name: "mise", bin: "mise"
            check: {|| ^mise outdated --json | from json | columns | length }
            apply: {|| ^mise upgrade }
        }
        {
            name: "Rust toolchains", bin: "rustup"
            check: {|| ^rustup check | complete | get stdout | lines | where { $in =~ "Update available" } | length }
            apply: {|| ^rustup self update; ^rustup update }
        }
        {
            name: "Cargo installs", bin: "cargo-install-update"
            check: {|| ^cargo install-update -l | lines | where { str ends-with "Yes" } | length }
            apply: {|| ^cargo install-update -a }
        }
        {
            name: "uv tools", bin: "uv"
            check: {|| null }
            apply: {|| ^uv tool upgrade --all }
        }
        {
            name: "npm globals", bin: "npm"
            check: {|| ^npm outdated -g --json | complete | get stdout | from json | columns | length }
            apply: {|| ^npm update -g }
        }
        {
            name: "Bun globals", bin: "bun"
            check: {|| ^bun outdated -g | complete | get stdout | lines | where { $in starts-with "│" and $in !~ "Package|─" } | length }
            apply: {|| ^bun update -g }
        }
    ] | where {|m| which $m.bin | is-not-empty }

    if ($managers | is-empty) { print "No supported package managers were found."; return }

    print $"(ansi yellow)Update summary(ansi reset)"
    let summary = $managers | each {|m|
        let count = try { do $m.check } catch { null }
        {manager: $m.name, outdated: ($count | default "?")}
    }
    print ($summary | table --index false)
    let known = $summary | get outdated | where { ($in | describe) == "int" } | math sum
    print $"($known) known outdated \(? = no quiet check\)"

    if (input --numchar 1 "Run updates now? [y/N] " | str lowercase) != "y" {
        print "\nNo updates applied."
        return
    }
    print ""
    for m in $managers {
        print $"(ansi cyan)--- Updating ($m.name)(ansi reset)"
        try { do $m.apply; print $"(ansi green)($m.name) complete.(ansi reset)\n" } catch {
            print $"(ansi red)($m.name) failed; continuing.(ansi reset)\n"
        }
    }
    print $"(ansi blue)Update run complete.(ansi reset)"
}

# ruff check --fix, then ruff format (default target: .)
def ruff-fmt [...targets: path]: nothing -> nothing {
    let targets = $targets | default --empty ["."]
    ^ruff check --fix ...$targets
    if $env.LAST_EXIT_CODE != 0 { return }
    ^ruff format ...$targets
}

# ruff check without fixes (default target: .)
def ruff-lint [...targets: path]: nothing -> nothing {
    ^ruff check ...($targets | default --empty ["."])
}

# Render an emoji (via noto-emoji) or an image file as colored ASCII art
def emoji2ascii [
    input: string  # emoji or image path
    width: int = 40
]: nothing -> nothing {
    let img = if ($input | path exists) { $input } else {
        let img = $nu.temp-dir | path join emoji.png
        let code = $input | _first-codepoint-hex
        http get --raw $"https://raw.githubusercontent.com/googlefonts/noto-emoji/main/png/128/emoji_u($code).png" | save --force $img
        $img
    }
    ^ascii-image-converter $img -C -W $width
}

# Lowercase hex codepoint of the first character (decodes the UTF-8 bytes)
def _first-codepoint-hex []: string -> string {
    let bytes = $in | split chars | first | encode utf-8 | encode hex | split chars | chunks 2 | each { str join | into int --radix 16 }
    let lead_bits = 7 - ($bytes | length | if $in == 1 { 0 } else { $in })
    $bytes | skip 1 | reduce --fold (($bytes | first) mod (2 ** $lead_bits)) {|b, acc| $acc * 64 + ($b mod 64) }
    | format number | get lowerhex | str replace "0x" ""
}
