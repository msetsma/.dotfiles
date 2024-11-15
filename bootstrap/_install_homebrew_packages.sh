#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the utils.sh script for logging functions
. "$SCRIPT_DIR/_utils.sh"

# Detect the operating system once and use it globally
OS_TYPE=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
elif [[ -n "$(grep -Ei 'Microsoft|WSL' /proc/version 2>/dev/null)" ]]; then
    OS_TYPE="wsl"
else
    OS_TYPE="other"
fi

# Function to check and install Homebrew packages using the Brewfile
install_homebrew_packages() {
    if ! command -v brew &>/dev/null; then
        error "Homebrew is not installed. Please run _install_prerequisites.sh first."
        exit 1
    fi

    # Determine the appropriate Brewfile based on the OS
    BREWFILE=""
    if [[ "$OS_TYPE" == "macos" ]]; then
        BREWFILE="$SCRIPT_DIR/../macos/homebrew/brewfile"
    elif [[ "$OS_TYPE" == "wsl" ]]; then
        BREWFILE="$SCRIPT_DIR/../wsl/homebrew/brewfile"
    else
        error "Unsupported operating system. No Brewfile available."
        exit 1
    fi

    # Check if the Brewfile exists
    if [[ ! -f "$BREWFILE" ]]; then
        error "Brewfile not found at $BREWFILE"
        return 1
    fi

    # Run `brew bundle check` and install missing dependencies
    local check_output
    check_output=$(brew bundle check --file="$BREWFILE" 2>&1)

    if echo "$check_output" | grep -q "The Brewfile's dependencies are satisfied."; then
        warning "The Brewfile's dependencies are already satisfied."
    else
        info "Installing Homebrew packages from $BREWFILE..."
        brew bundle install --file="$BREWFILE"
        success "Homebrew packages installed successfully!"
    fi
}

# Main script execution
if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    install_homebrew_packages
fi
