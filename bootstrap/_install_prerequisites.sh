#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the utils.sh script for logging functions
. "$SCRIPT_DIR/_utils.sh"

install_xcode() {
    info "Installing Apple's CLI tools (prerequisites for Git and Homebrew)..."
    if xcode-select -p &>/dev/null; then
        warning "Xcode command line tools are already installed"
    else
        xcode-select --install
        sudo xcodebuild -license accept
    fi
}

install_homebrew() {
    info "Installing Homebrew..."
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"

    if hash brew &>/dev/null; then
        warning "Homebrew is already installed"
    else
        sudo --validate
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Configure Homebrew for WSL if necessary
    if [[ -n "$(grep -Ei 'Microsoft|WSL' /proc/version 2>/dev/null)" ]]; then
        info "Configuring Homebrew for WSL..."
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.bashrc
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
}

# Main script execution
if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        install_xcode
        install_homebrew
    elif [[ -n "$(grep -Ei 'Microsoft|WSL' /proc/version 2>/dev/null)" ]]; then
        install_homebrew
    else
        error "Unsupported operating system. Prerequisite installation skipped."
        exit 1
    fi
fi
