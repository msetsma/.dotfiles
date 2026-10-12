#!/bin/zsh

emulate -LR zsh
setopt errexit nounset pipefail

SCRIPT_DIR="${0:A:h}"
FUNCTION_DIR="${SCRIPT_DIR:h}/functions/public"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fake_bin="$tmpdir/bin"
repo_dir="$tmpdir/repo"
opened_url_file="$tmpdir/opened-url"

mkdir -p "$fake_bin" "$repo_dir"

cat > "$fake_bin/open" <<'FAKE_OPEN'
#!/bin/zsh

emulate -LR zsh
setopt errexit nounset pipefail

print -r -- "$1" > "$OPENED_URL_FILE"
FAKE_OPEN
chmod +x "$fake_bin/open"

export PATH="$fake_bin:$PATH"
export IS_MAC=1
export IS_WSL_INTEROP=0
export OPENED_URL_FILE="$opened_url_file"

fpath=("$FUNCTION_DIR" $fpath)
autoload -Uz repo

assert_opened_url() {
  local remote="$1"
  local expected="$2"

  (
    cd "$repo_dir"
    git init -q
    git remote remove origin 2>/dev/null || true
    git remote add origin "$remote"
    : > "$opened_url_file"

    repo
  )

  local actual
  actual="$(<"$opened_url_file")"
  if [[ "$actual" != "$expected" ]]; then
    print -u2 -- "Expected opened URL:"
    print -u2 -- "$expected"
    print -u2 -- "Actual opened URL:"
    print -u2 -- "$actual"
    exit 1
  fi
}

assert_opened_url \
  "git@github.com-work:Steelcase-AI/dsp-foundry-models.git" \
  "https://github.com/Steelcase-AI/dsp-foundry-models"

print -- "repo tests passed"
