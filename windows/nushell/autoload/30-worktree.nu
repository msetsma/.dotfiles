# Claude Code worktree helpers, ported from common/zsh/functions/public/work-tree.
#
# Convention: a worktree for feature <name> on repo <repo> lives at the sibling
# path "<repo>-<name>" on branch "feat/<name>", so listing and teardown need no
# bookkeeping. Inside WezTerm a new tab replaces the zsh version's tmux window.

def _ccwt-root []: nothing -> string {
    let result = ^git rev-parse --show-toplevel | complete
    if $result.exit_code != 0 { error make {msg: "ccwt: not inside a git repository"} }
    $result.stdout | str trim
}

def _ccwt-dirty [dir: string]: nothing -> bool {
    ^git -C $dir status --porcelain | str trim | is-not-empty
}

# Create a worktree + feat/<name> branch, sync the Python env, launch claude
def --env ccwt [
    name: string  # feature name
    --no-launch   # only create the worktree
]: nothing -> nothing {
    let root = _ccwt-root
    let branch = $"feat/($name)"
    let dir = $"($root)-($name)"
    if ($dir | path exists) { error make {msg: $"ccwt: path already exists: ($dir)"} }

    ^git worktree add $dir -b $branch
    if $env.LAST_EXIT_CODE != 0 { error make {msg: "ccwt: git worktree add failed"} }

    # .venv and .env are untracked, so a fresh worktree never has them
    if ([pyproject.toml uv.lock] | any {|f| $dir | path join $f | path exists }) {
        print $"ccwt: syncing environment in ($dir) ..."
        try { do { cd $dir; ^uv sync } } catch { print -e "ccwt: uv sync failed, env may be incomplete" }
    }
    let env_file = $root | path join .env
    if ($env_file | path exists) and not ($dir | path join .env | path exists) {
        cp $env_file ($dir | path join .env)
        print "ccwt: copied .env into worktree"
    }

    if $no_launch {
        print $"ccwt: worktree ready at ($dir) on ($branch) \(launch skipped\)"
    } else if ($env.WEZTERM_PANE? | is-not-empty) {
        ^wezterm cli spawn --cwd $dir -- claude | ignore
        print $"ccwt: launched claude in a new WezTerm tab for '($name)'"
    } else {
        cd $dir
        print $"ccwt: in ($dir) on ($branch), launch with: claude"
    }
}

# List active worktrees with their branches
def ccwt-ls []: nothing -> nothing {
    _ccwt-root | ignore
    ^git worktree list
}

# Tear down a worktree and its branch; refuses on uncommitted changes
def ccwt-rm [
    name: string  # feature name
    --force       # discard uncommitted changes and unmerged branch
]: nothing -> nothing {
    let root = _ccwt-root
    let branch = $"feat/($name)"
    let dir = $"($root)-($name)"
    if not ($dir | path exists) { error make {msg: $"ccwt-rm: no worktree at ($dir)"} }
    if not $force and (_ccwt-dirty $dir) {
        error make {msg: $"ccwt-rm: ($dir) has uncommitted changes. Commit them or pass --force."}
    }

    # a second --force tells git to discard changes as well
    if $force { ^git worktree remove --force --force $dir } else { ^git worktree remove --force $dir }
    if $env.LAST_EXIT_CODE != 0 { error make {msg: "ccwt-rm: git worktree remove failed"} }

    if $force {
        ^git branch -D $branch
    } else if (^git branch -d $branch | complete).exit_code != 0 {
        print $"ccwt-rm: branch ($branch) not deleted \(unmerged\). Use git branch -D to force."
    }
    ^git worktree prune
    print $"ccwt-rm: removed worktree ($dir)"
}

# Remove every clean worktree whose branch is merged into HEAD
def ccwt-sweep [
    --dry-run  # only print what would be removed
]: nothing -> nothing {
    let root = _ccwt-root
    let merged = ^git branch --merged '--format=%(refname:short)' | lines

    ^git worktree list --porcelain
    | lines
    | where { str starts-with "worktree " }
    | each { str replace "worktree " "" }
    | where {|wt| $wt != $root and not (_ccwt-dirty $wt) }
    | each {|wt|
        let name = $wt | path basename | split row "-" | last
        let branch = $"feat/($name)"
        if $branch not-in $merged { return }
        if $dry_run { print $"would remove: ($wt) \(($branch)\)" } else { ccwt-rm $name }
    }
    | ignore
}
