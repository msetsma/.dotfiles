#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions
. "$SCRIPT_DIR/_utils.sh"


setup_common() {
    info "===================="
    info "Common Setup"
    info "===================="

    info "Running prerequisites installation..."
    "$SCRIPT_DIR/_install_prerequisites.sh"

    info "Running Homebrew package installation..."
    "$SCRIPT_DIR/_install_homebrew_packages.sh"

}

setup_macos() {
    info "===================="
    info "Mac OS Setup"
    info "===================="


    info "Applying macOS system defaults..."
    "$SCRIPT_DIR/_set_osx_defaults.sh"

    info "Creating symbolic links for dotfiles..."
    "$SCRIPT_DIR/_symlink_dotfiles.sh"

    success "macOS setup completed successfully!"
}

setup_wsl() {
    info "===================="
    info "WSL Setup"
    info "===================="

    info "Running WSL Homebrew package installation..."
    "$SCRIPT_DIR/_install_homebrew_packages.sh"

    info "Creating symbolic links for dotfiles..."
    "$SCRIPT_DIR/_symlink_dotfiles.sh"

    success "WSL setup completed successfully!"
}


chmod +x bootstrap/_install_prerequisites.sh
chmod +x bootstrap/_install_homebrew_packages.sh
chmod +x bootstrap/_symlink_dotfiles.sh
setup_common

if [[ "$OSTYPE" == "darwin"* ]]; then
    chmod +x bootstrap/_set_osx_defaults.sh
    setup_macos
elif [[ -n "$(grep -Ei 'Microsoft|WSL' /proc/version 2>/dev/null)" ]]; then
    setup_wsl
else
    error "Unsupported operating system."
    exit 1
fi