# ZLE widgets and keybindings.

_zsh_bind_widget_key() {
  local widget="$1"
  shift
  local key
  local keymap

  zle -N "$widget"
  for key in "$@"; do
    for keymap in main emacs viins vicmd; do
      bindkey -M "$keymap" "$key" "$widget" 2>/dev/null
    done
  done
}

# Search custom aliases/functions/commands.
_zsh_bind_widget_key cmds-fzf-widget '^g'

# Command-line editing helper.
_zsh_bind_widget_key zle-helper-widget '^[h' '^[H' '\M-h' '\M-H'

# Copy the last tmux command output.
_zsh_bind_widget_key clip-widget '^[y' '^[Y' '\M-y' '\M-Y'

unfunction _zsh_bind_widget_key
