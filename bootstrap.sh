#!/bin/bash

# Bootstrap script to set up WezTerm and Zsh configurations

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
DOTFILES_DIR="$HOME/.dotfiles"
ZSH_DIR="$HOME/.zsh"

# Function to create a symbolic link
create_symlink() {
  local source_file="$1"
  local target_file="$2"

  # Check if the target file already exists
  if [ -L "$target_file" ]; then
    echo "Symlink already exists: $target_file"
  elif [ -e "$target_file" ]; then
    echo "File exists and will be backed up: $target_file"
    mv "$target_file" "$target_file.backup"
    ln -s "$source_file" "$target_file"
    echo "Created symlink: $source_file -> $target_file (original backed up)"
  else
    ln -s "$source_file" "$target_file"
    echo "Created symlink: $source_file -> $target_file"
  fi
}

# Create the .zsh directory if it doesn't exist
mkdir -p "$ZSH_DIR"

# WezTerm configuration
create_symlink "$DOTFILES_DIR/wezterm/wezterm.lua" "$HOME/.wezterm.lua"



echo "Setup complete!"
