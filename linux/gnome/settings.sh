#!/usr/bin/env bash
# GNOME settings that mirror the macOS AeroSpace workflow where GNOME allows it.
# AeroSpace is a tiling WM; GNOME is kept for touch/pen support on the Surface,
# so only the workspace and window keybinds carry over.
#
#   alt+1..7        switch to workspace N         (AeroSpace: workspace N)
#   alt+shift+1..7  move window to workspace N    (AeroSpace: move-node-to-workspace N)
#   alt+f           toggle maximize               (AeroSpace: fullscreen)
#   super+Return    new Ghostty window
#
# Re-run any time; gsettings writes are idempotent.
set -euo pipefail

WORKSPACES=7
CUSTOM_KB_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

if ! command -v gsettings >/dev/null 2>&1; then
  echo "gsettings not found; is this a GNOME session?" >&2
  exit 1
fi

set_workspaces() {
  gsettings set org.gnome.mutter dynamic-workspaces false
  gsettings set org.gnome.desktop.wm.preferences num-workspaces "$WORKSPACES"
  gsettings set org.gnome.mutter workspaces-only-on-primary true

  local n
  for n in $(seq 1 "$WORKSPACES"); do
    # Free alt+N from the dash "switch to application N" default first
    gsettings set org.gnome.shell.keybindings "switch-to-application-$n" "[]"
    gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$n" "['<Alt>$n']"
    gsettings set org.gnome.desktop.wm.keybindings "move-to-workspace-$n" "['<Shift><Alt>$n']"
  done
}

set_window_keys() {
  gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Alt>f']"
  gsettings set org.gnome.mutter edge-tiling true
}

set_terminal_key() {
  local path="$CUSTOM_KB_PATH/ghostty/"
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$path']"
  gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" name "Ghostty"
  gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" command "ghostty"
  gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" binding "<Super>Return"
}

set_appearance() {
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
  gsettings set org.gnome.desktop.interface monospace-font-name "JetBrainsMono Nerd Font 11"
  # Surface Pro 7 panel looks best at 150-175%; fractional scaling is still an
  # experimental mutter flag. Pick the scale in Settings > Displays afterwards.
  gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
}

set_input() {
  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
}

main() {
  set_workspaces
  set_window_keys
  set_terminal_key
  set_appearance
  set_input
  echo "GNOME settings applied. Log out and back in for workspace changes to settle."
}

main "$@"
