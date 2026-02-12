#!/usr/bin/env bash
# make_sh_executable.sh
# Recursively find .sh files, dry-run, confirm, then chmod +x with safety checks.

set -euo pipefail
IFS=$'\n\t'

# ===== Configurable settings =====
MAX_FILES=100

# ===== Functions =====
die() {
    echo "❌ $*" >&2
    exit 1
}

confirm() {
    local prompt="$1"
    read -rp "$prompt (y/N): " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

find_sh_files() {
    mapfile -t sh_files < <(find . -type f -name "*.sh" 2>/dev/null)
}

dry_run() {
    echo "Dry run: The following ${#sh_files[@]} file(s) would be made executable:"
    printf '%s\n' "${sh_files[@]}"
}

apply_chmod() {
    for file in "${sh_files[@]}"; do
        if [[ ! -x "$file" ]]; then
            chmod +x "$file"
            echo "✅ Made executable: $file"
        else
            echo "ℹ Already executable: $file"
        fi
    done
}

# ===== Main =====
find_sh_files

# No files found
if ((${#sh_files[@]} == 0)); then
    die "No .sh files found."
fi

# Safety check
if ((${#sh_files[@]} > MAX_FILES)); then
    echo "⚠ Found ${#sh_files[@]} .sh files — exceeds safety limit ($MAX_FILES)."
    if ! confirm "Do you want to override and proceed?"; then
        die "Aborted due to safety limit."
    fi
fi

dry_run

if confirm "Proceed with chmod +x on these files?"; then
    apply_chmod
    echo "🎯 Done."
else
    die "Aborted by user."
fi
