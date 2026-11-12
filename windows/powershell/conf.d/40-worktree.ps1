# Claude Code worktree helpers, ported from windows/nushell/autoload/30-worktree.nu.
#
# Convention: a worktree for feature <name> on repo <repo> lives at the sibling
# path "<repo>-<name>" on branch "feat/<name>", so listing and teardown need no
# bookkeeping. Inside WezTerm a new tab replaces the zsh version's tmux window.

function _ccwt-root {
    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'ccwt: not inside a git repository' }
    $root.Trim()
}

function _ccwt-dirty([string]$Dir) {
    [bool](git -C $Dir status --porcelain)
}

# .SYNOPSIS
# Create a worktree + feat/<name> branch, sync the Python env, launch claude
function ccwt {
    param([Parameter(Mandatory)][string]$Name, [switch]$NoLaunch)
    $root = _ccwt-root
    $branch = "feat/$Name"
    $dir = "$root-$Name"
    if (Test-Path $dir) { throw "ccwt: path already exists: $dir" }

    git worktree add $dir -b $branch
    if ($LASTEXITCODE -ne 0) { throw 'ccwt: git worktree add failed' }

    # .venv and .env are untracked, so a fresh worktree never has them
    if ('pyproject.toml', 'uv.lock' | Where-Object { Test-Path (Join-Path $dir $_) }) {
        Write-Host "ccwt: syncing environment in $dir ..."
        Push-Location $dir
        try { uv sync; if ($LASTEXITCODE -ne 0) { Write-Warning 'ccwt: uv sync failed, env may be incomplete' } }
        finally { Pop-Location }
    }
    $envFile = Join-Path $root '.env'
    if ((Test-Path $envFile) -and -not (Test-Path (Join-Path $dir '.env'))) {
        Copy-Item $envFile (Join-Path $dir '.env')
        Write-Host 'ccwt: copied .env into worktree'
    }

    if ($NoLaunch) {
        Write-Host "ccwt: worktree ready at $dir on $branch (launch skipped)"
    } elseif ($env:WEZTERM_PANE) {
        $null = wezterm cli spawn --cwd $dir -- claude
        Write-Host "ccwt: launched claude in a new WezTerm tab for '$Name'"
    } else {
        Set-Location $dir
        Write-Host "ccwt: in $dir on $branch, launch with: claude"
    }
}

# .SYNOPSIS
# List active worktrees with their branches
function ccwt-ls {
    $null = _ccwt-root
    git worktree list
}

# .SYNOPSIS
# Tear down a worktree and its branch; refuses on uncommitted changes
function ccwt-rm {
    param([Parameter(Mandatory)][string]$Name, [switch]$Force)
    $root = _ccwt-root
    $branch = "feat/$Name"
    $dir = "$root-$Name"
    if (-not (Test-Path $dir)) { throw "ccwt-rm: no worktree at $dir" }
    if (-not $Force -and (_ccwt-dirty $dir)) {
        throw "ccwt-rm: $dir has uncommitted changes. Commit them or pass -Force."
    }

    # a second --force tells git to discard changes as well
    if ($Force) { git worktree remove --force --force $dir } else { git worktree remove --force $dir }
    if ($LASTEXITCODE -ne 0) { throw 'ccwt-rm: git worktree remove failed' }

    if ($Force) {
        git branch -D $branch
    } else {
        git branch -d $branch 2>$null
        if ($LASTEXITCODE -ne 0) { Write-Host "ccwt-rm: branch $branch not deleted (unmerged). Use git branch -D to force." }
    }
    git worktree prune
    Write-Host "ccwt-rm: removed worktree $dir"
}

# .SYNOPSIS
# Remove every clean worktree whose branch is merged into HEAD
function ccwt-sweep {
    param([switch]$DryRun)
    $root = _ccwt-root
    $merged = git branch --merged '--format=%(refname:short)'

    git worktree list --porcelain |
        Where-Object { $_.StartsWith('worktree ') } |
        ForEach-Object { $_.Substring(9) } |
        Where-Object { (Resolve-Path $_).Path -ne (Resolve-Path $root).Path -and -not (_ccwt-dirty $_) } |
        ForEach-Object {
            $name = (Split-Path $_ -Leaf).Split('-')[-1]
            $branch = "feat/$name"
            if ($merged -notcontains $branch) { return }
            if ($DryRun) { Write-Host "would remove: $_ ($branch)" } else { ccwt-rm $name }
        }
}
