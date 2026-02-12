rld() {
    echo "Reloading Zsh configuration..."
    exec zsh
}

update() {
    echo "Updating Homebrew and installed packages..."
    brew update && brew upgrade && (brew cleanup || true)
    
    echo "Updating Rust toolchain..."
    rustup update
    
    echo "Updating Cargo packages..."
    cargo install $(cargo install --list | grep -E '^\w' | cut -d' ' -f1)
    
    echo "All updates completed."
}

# Function to source all .sh or .zsh files in a given directory
# Usage: source_folder_contents /path/to/folder
source_folder_contents() {
    # Check for the correct number of arguments
    if [ $# -ne 1 ]; then
        return 1
    fi

    local target_dir="$1"
    target_dir=${=target_dir}
    [[ "$target_dir" != */ ]] && target_dir="$target_dir/"

    # Check if the target is a valid directory and exists
    if [ ! -d "$target_dir" ]; then
        echo "Error: '$target_dir' is not a valid directory or does not exist." >&2 # Send error to stderr
        return 1
    fi

    local sourced_count=0
    local error_count=0
    local file_found=false # Flag to check if any files were considered

    # Temporarily disable the 'nomatch' option so the glob doesn't cause an error
    local original_options="$(setopt | grep nomatch)" # Capture current state
    setopt nonomatch

    # Loop through files ending in .sh or .zsh within the directory.
    for script_file in "${target_dir}"*.sh "${target_dir}"*.zsh; do
        # Check if the file exists and is a regular file
        if [ -f "$script_file" ]; then # <--- This is line ~39/40/41 depending on formatting
            file_found=true # Indicate we found at least one file to consider
            # *** CHANGED THIS LINE BACK TO JUST 'source' ***
            if source "$script_file"; then # <--- This is line ~43 in your error message
                ((sourced_count++))
            else
                echo "  Error sourcing $script_file" >&2 # Send error to stderr
                ((error_count++))
            fi
        fi
    done

    # Restore the original 'nomatch' option state
    if [[ "$original_options" == "nonomatch" ]]; then
       setopt nonomatch # Was originally off
    else
       setopt nomatch # Was originally on (or not explicitly set, which defaults to on)
    fi

    # Return status code: 0 for success (or no errors), 1 for errors during sourcing
    if [ $error_count -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

gitnav() {
  emulate -L zsh
  setopt pipefail

  local selected cache_file cache_ttl=300 current_dir force_refresh=0
  current_dir=$(pwd)

  # Support -f flag to force refresh
  if [[ "$1" == "-f" ]] || [[ "$1" == "--force" ]]; then
    force_refresh=1
  fi

  cache_file="${TMPDIR:-/tmp}/gitnav_cache_${USER}_$(echo "$current_dir" | md5sum | cut -d' ' -f1 2>/dev/null || echo "$current_dir" | md5 | cut -d' ' -f1).txt"

  # Check cache validity (5 min TTL)
  local use_cache=0
  if (( force_refresh == 0 )) && [[ -f "$cache_file" ]] && (( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) < cache_ttl )); then
    use_cache=1
  fi

  local listing
  if (( use_cache )); then
    listing=$(<"$cache_file")
  else
    # Find .git directories and extract parent path efficiently with sed
    # Remove /.git/ suffix (with trailing slash from fd) to get actual repo paths
    # Format: name\trelative_path\tfull_path (sorted by name)
    local repos_raw repo_path rel_path repo_name
    repos_raw=$(fd -t d -H -I '^\.git$' . --max-depth 5 2>/dev/null | sed 's|/\.git/$||')

    [[ -z "$repos_raw" ]] && {
      print -P "%F{yellow}No Git repositories found in $current_dir%f"
      return 1
    }

    # Build listing efficiently with process substitution
    listing=$(
      echo "$repos_raw" | while IFS= read -r repo_path; do
        repo_name="$(basename "$repo_path")"
        rel_path="${repo_path#./}"
        [[ "$rel_path" == "$repo_path" ]] && rel_path="$repo_path" || rel_path="./$rel_path"
        printf "%s\t%s\t%s\n" "$repo_name" "$rel_path" "$repo_path"
      done | sort -t$'\t' -k1,1
    )

    # Cache the results
    echo "$listing" > "$cache_file"
  fi

  [[ -z "$listing" ]] && {
    print -P "%F{yellow}No Git repositories found in $current_dir%f"
    return 1
  }

  # FZF picker with preview
  selected=$(
    echo "$listing" |
      fzf --prompt='Select repo > ' \
          --header='Name → Path (↑/↓ navigate, ⏎ select, Esc cancel)' \
          --delimiter='\t' \
          --with-nth=1,2 \
          --preview='
            repo_path={3}
            cd "$repo_path" 2>/dev/null || exit 0
            echo -e "\033[1;36mRepository:\033[0m $(basename "$repo_path")"
            echo -e "\033[1;36mLocation:\033[0m $repo_path"
            echo ""
            if git rev-parse --git-dir >/dev/null 2>&1; then
              branch=$(git branch --show-current 2>/dev/null)
              [[ -n "$branch" ]] && echo -e "\033[1;33mBranch:\033[0m $branch" || echo -e "\033[1;33mBranch:\033[0m (detached HEAD)"
              echo ""
              echo -e "\033[1;35mStatus:\033[0m"
              git status -sb 2>/dev/null | head -10
              echo ""
              echo -e "\033[1;32mRecent commits:\033[0m"
              git log --oneline --color=always -5 2>/dev/null
            fi
          ' \
          --preview-window=right:60%:wrap \
          --layout=reverse \
          --height=90% \
          --border \
          --no-sort |
      cut -f3
  )

  [[ -n "$selected" ]] && {
    cd "$selected" || return
    local rel_display="${selected#$current_dir/}"
    [[ "$rel_display" == "$selected" ]] && rel_display="$selected"
    print -P "\n%F{green}✓%f Navigated to: %F{cyan}$rel_display%f"

    # Show quick git info
    if git rev-parse --git-dir >/dev/null 2>&1; then
      local branch=$(git branch --show-current 2>/dev/null)
      [[ -n "$branch" ]] && print -P "  Branch: %F{yellow}$branch%f"
    fi
  }
}
