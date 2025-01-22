#!/bin/bash
apply_osx_system_defaults() {
    info "Applying OSX system defaults..."

    # Enable key repeats
    defaults write -g ApplePressAndHoldEnabled -bool false

    # Hide icons on desktop
    defaults write com.apple.finder CreateDesktop -bool false

    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    # Show hidden files inside the finder
    defaults write com.apple.finder "AppleShowAllFiles" -bool true

    # Show Status Bar
    defaults write com.apple.finder "ShowStatusBar" -bool true

    # Do not show warning when changing the file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Do not rearrange spaces automatically
    defaults write com.apple.dock "mru-spaces" -bool false

    # disable displays have seprate spaces
    defaults write com.apple.dock expose-group-apps -bool true && killall Dock

    # group windows by application 
    defaults write com.apple.dock expose-group-apps -bool true && killall Dock

    # allow drag with ctrl + cmd any where in window
    defaults write -g NSWindowShouldDragOnGesture -bool true

    # disable windows opening animations
    defaults write -g NSAutomaticWindowAnimationsEnabled -bool false

if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    apply_osx_system_defaults
fi
