#!/usr/bin/env nu

def error [msg: string] {
    echo "Error: $msg"
    exit 1
}

# Placeholder functions for color scheme updates
def generate_nushell_config [] {
    # Add logic to set Nushell colors here
    echo "Setting Nushell colors (placeholder)."
}

def generate_nvim_config [] {
    # Add logic to update Neovim colors here
    echo "Setting Neovim colors (placeholder)."
}

def generate_yazi_config [] {
    # Add logic to set Yazi colors here
    echo "Setting Yazi colors (placeholder)."
}

def generate_wezterm_config [] {
    # Add logic to update WezTerm colors here
    echo "Setting WezTerm colors (placeholder)."
}

def main [file: string] {
  if file == $null {
      error "No colorscheme profile provided"
  }

  let colorscheme_profile = $env.argv.0

  # Define paths
  let colorscheme_file = ($env.HOME | path join "github/dotfiles-latest/colorscheme/list/$colorscheme_profile")
  let active_file = ($env.HOME | path join "github/dotfiles-latest/colorscheme/active/active-colorscheme.nu")

  # Check if the colorscheme file exists
  if not ($colorscheme_file | path exists) {
      error "Colorscheme file '$colorscheme_file' does not exist."
  }

  # If active-colorscheme.nu doesn't exist, create it
  if not ($active_file | path exists) {
      echo "Active colorscheme file not found. Creating '$active_file'."
      cp $colorscheme_file $active_file
      let UPDATED = true
  } else {
      # Compare the new colorscheme with the active one
      let diff_result = (open $colorscheme_file | diff $active_file)
      if $diff_result != "" {
          let UPDATED = true
      } else {
          let UPDATED = false
      }
  }
  # If there's an update, replace the active colorscheme and perform necessary actions
  if $UPDATED {
      echo "Updating active colorscheme to '$colorscheme_profile'."

      # Replace the contents of active-colorscheme.nu
      cp $colorscheme_file $active_file

      # Copy the colorscheme_file to another location if needed
      cp $colorscheme_file ($env.HOME | path join "github/dotfiles-latest/neovim/neobean/lua/config/active-colorscheme.nu")

      # Source the active colorscheme
      source $active_file

      # Placeholder actions for updating tools
      generate_nushell_config
      generate_nvim_config
      generate_yazi_config
      generate_wezterm_config

      # Add any additional custom commands here
      echo "Colorscheme update complete."
  }
} 
