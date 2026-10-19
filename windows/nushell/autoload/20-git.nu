# Git helpers: gcm, gfzf, gitnav, repo.
#
# fzf on Windows runs --preview through cmd.exe, so previews stay plain
# `git ... && git ...` command lines.

# Commit staged changes with a one-line message
def gcm [...message: string]: nothing -> nothing {
    let msg = $message | str join " " | str trim
    if ($msg | is-empty) { error make {msg: "usage: gcm <commit message>"} }
    ^git commit -m $msg
}

# Fuzzy-pick a local or remote branch (most recent first) and check it out
def gfzf []: nothing -> nothing {
    let branches = ^git for-each-ref --sort=-committerdate refs/heads/ refs/remotes/ '--format=%(refname:short)'
        | lines
        | where { $in !~ 'HEAD$' }
    if ($branches | is-empty) { error make {msg: "no branches found"} }

    let pick = $branches | str join "\n" | ^fzf --no-hscroll --ansi --preview-window right:60% --preview 'git log --graph --oneline --decorate --color=always -20 {1}' | str trim
    if ($pick | is-empty) { return }
    print $"Checking out branch: ($pick)"
    ^git checkout $pick
}

# Fuzzy-jump to a git repo under a root (cached for 5 minutes)
def --env gitnav [
    root?: path  # search root (default: $env.GITNAV_ROOT or ~)
    --force (-f) # ignore the cache and rescan
]: nothing -> nothing {
    let root = $root | default ($env.GITNAV_ROOT? | default $nu.home-dir) | path expand
    let cache = $nu.cache-dir | path join gitnav $"($root | hash md5).txt"
    let fresh = ($cache | path exists) and ((date now) - (ls $cache | get 0.modified) < 5min)

    let listing = if $fresh and not $force { open --raw $cache } else {
        print $"(ansi dark_gray)scanning ($root) for repos...(ansi reset)"
        let rows = ^fd --type d --hidden --no-ignore --max-depth 5 '^\.git$' $root
            | lines
            | each { str replace --regex '[\\/]$' '' | path dirname }
            | sort-by { path basename }
            | each {|dir| $"($dir | path basename)\t($dir)" }
            | str join "\n"
        mkdir ($cache | path dirname)
        $rows | save --force $cache
        $rows
    }
    if ($listing | is-empty) { error make {msg: $"no git repositories found in ($root)"} }

    let pick = $listing
        | ^fzf --prompt 'repo > ' --delimiter "\t" --with-nth 1 --accept-nth 2 --no-sort --preview-window right:60%:wrap --preview 'git -C {2} -c color.status=always status -sb && echo. && git -C {2} log --oneline --color=always -8'
        | str trim
    if ($pick | is-empty) { return }

    cd $pick
    let branch = ^git branch --show-current | str trim
    print $"(ansi green)✓(ansi reset) ($pick | path basename) (ansi yellow)($branch)(ansi reset)"
}

# Open the origin remote in the browser (GitHub only)
def repo []: nothing -> nothing {
    let remote = ^git remote get-url origin | complete
    if $remote.exit_code != 0 { error make {msg: "no 'origin' remote found"} }

    let url = $remote.stdout | str trim | str replace --regex '\.git$' ''
    let found = $url | parse --regex '^(?:git@|ssh://git@|https://(?:[^@/]+@)?)github\.com[^:/]*[:/](?<path>.+)$'
    if ($found | is-empty) { error make {msg: $"unsupported remote: ($url)"} }
    start $"https://github.com/($found.0.path)"
}
