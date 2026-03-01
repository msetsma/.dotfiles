git_fzf_checkout() {
    # Check if fzf is installed and the command is available
    if ! command -v fzf &>/dev/null; then
        # If fzf is not found, define a fallback function that prints an error
        fzf_checkout() {
            echo "Error: fzf command not found."
            echo "Please install fzf to use this function (e.g., 'brew install fzf' on macOS)."
            return 1
        }
    else
        # Define the fzf_checkout function (or gbc - git branch checkout)
        # This function uses fzf to select a git branch and then checks it out.
        fzf_checkout() {
            # Use git for-each-ref to list branches and remote branches.
            # --sort=-committerdate shows most recent first.
            # --format='%(refname:short)' gives clean branch names (e.g., main, origin/feature).
            # grep -v HEAD excludes the 'origin/HEAD -> origin/main' line.
            local branch_list
            branch_list=$(git for-each-ref --sort=-committerdate refs/heads/ refs/remotes/ \
                --format='%(refname:short)' | grep -v HEAD)

            # Check if any branches were found
            if [ -z "$branch_list" ]; then
                echo "No branches found in this repository."
                return 1
            fi

            # Pipe the list to fzf for interactive selection.
            # --preview 'git log ... {1}' shows the log of the selected branch ({1} is the selected line).
            local selected_branch
            selected_branch=$(
                echo "$branch_list" | fzf \
                    --no-hscroll \
                    --ansi \
                    --preview 'git log --graph --date=short --pretty=format:"%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(green)(%cr)%Creset %C(blue)<%an>%Creset" {1} | head -20' \
                    --preview-window right:60%
            )

            # Check if a branch was selected (fzf returns nothing if cancelled)
            if [ -z "$selected_branch" ]; then
                echo "No branch selected. Aborting checkout."
                return 0 # Return success as cancellation is a valid user action
            fi

            # Checkout the selected branch
            echo "Checking out branch: $selected_branch"
            git checkout "$selected_branch"
        }
    fi
}