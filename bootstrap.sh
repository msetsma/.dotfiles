#!/bin/bash

. scripts/bootstrap/utils.sh
. scripts/bootstrap/init.sh
. scripts/bootstrap/install_homebrew.sh
. scripts/bootstrap/set_osx_defaults.sh
. scripts/bootstrap/create_symlinks.sh

info "Dotfiles intallation initialized..."
read -p "Install apps? [y/n] " install_apps
read -p "Overwrite existing dotfiles? [y/n] " overwrite_dotfiles

if [[ "$install_apps" == "y" ]]; then
    printf "\n"
    info "===================="
    info "Prerequisites"
    info "===================="

    install_xcode
    install_homebrew

    printf "\n"
    info "===================="
    info "Apps"
    info "===================="

    run_brew_bundle
fi

printf "\n"
info "===================="
info "OSX System Defaults"
info "===================="

# register_keyboard_shortcuts
apply_osx_system_defaults

printf "\n"
info "===================="
info "Symbolic Links"
info "===================="

chmod +x ./scripts/bootstrap/create_symlinks.sh
if [[ "$overwrite_dotfiles" == "y" ]]; then
    warning "Deleting existing dotfiles..."
    ./scripts/bootstrap/create_symlinks.sh --delete --include-files
fi
./scripts/bootstrap/create_symlinks.sh --create

success "Dotfiles set up successfully."