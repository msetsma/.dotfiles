#!/bin/zsh
# Move all windows to their assigned workspaces.
# Usage: bind to a hotkey in aerospace.toml or run manually.

AERO="/opt/homebrew/bin/aerospace"
FALLBACK_WORKSPACE="6"

typeset -A APP_WORKSPACE=(
  Ghostty              1
  Code                 2
  "Visual Studio Code" 2
  Firefox              3
  "Microsoft Teams"    4
  Obsidian             5
  "Open WebUI"         6
)

$AERO list-windows --all --format '%{window-id}|%{app-name}|%{workspace}' | while IFS='|' read -r wid app ws; do
  target="${APP_WORKSPACE[$app]}"
  if [[ -n "$target" ]]; then
    $AERO move-node-to-workspace --window-id "$wid" "$target"
  elif [[ "$ws" =~ ^[1-5]$ ]]; then
    $AERO move-node-to-workspace --window-id "$wid" "$FALLBACK_WORKSPACE"
  fi
done
