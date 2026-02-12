rld() {
    echo "Reloading Zsh configuration..."

    if [[ -n "$ZDOTDIR" ]]; then
        source "$ZDOTDIR/.zshrc"
    else
        source "$HOME/.zshrc"
    fi

    exec zsh
}

# Function to source all .sh or .zsh files in a given directory
# Usage: source_folder_contents /path/to/folder
source_folder_contents() {
    # Check for the correct number of arguments
    if [ $# -ne 1 ]; then
        return 1
    fi

    local target_dir="$1"

    # Resolve the path (handles ~ and other expansions in Zsh)
    # Using the = operator to expand the path before further processing
    target_dir=${=target_dir}

    # Add a trailing slash if it's missing, for consistent globbing
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