#!/bin/bash

# Source the utils.sh script for logging functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_utils.sh"

# Function to symlink dotfiles using GNU Stow
symlink_dotfiles() {
    info "Creating symbolic links for dotfiles using GNU Stow..."

    # Navigate to the root of the dotfiles directory
    DOTFILES_DIR="$SCRIPT_DIR/.."
    cd "$DOTFILES_DIR" || exit

    # Symlink common dotfiles
    stow common

    # Detect the operating system and symlink platform-specific dotfiles
    if [[ "$OSTYPE" == "darwin"* ]]; then
        info "Setting up macOS-specific dotfiles..."
        stow macos
    elif [[ -n "$(grep -Ei 'Microsoft|WSL' /proc/version 2>/dev/null)" ]]; then
        info "Setting up WSL-specific dotfiles..."
        stow wsl
    else
        info "No additional platform-specific dotfiles to set up."
    fi

    success "Dotfiles setup complete!"
}

# Execute the symlinking function
symlink_dotfiles
