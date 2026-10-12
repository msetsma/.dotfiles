# Platform adapters shared by aliases, widgets, and functions.

_clip() {
  if (( ${IS_MAC:-0} )) && (( $+commands[pbcopy] )); then
    command pbcopy "$@"
  elif (( ${IS_WSL_INTEROP:-0} )) && (( $+commands[clip.exe] )); then
    command clip.exe "$@"
  elif (( $+commands[wl-copy] )); then
    command wl-copy "$@"
  elif (( $+commands[xclip] )); then
    command xclip -selection clipboard "$@"
  elif (( $+commands[xsel] )); then
    command xsel --clipboard --input "$@"
  else
    print -u2 "No clipboard backend found. Install pbcopy, clip.exe via WSL interop, wl-copy, xclip, or xsel."
    return 127
  fi
}

alias -g copy='| _clip'

if (( ${IS_WSL_INTEROP:-0} )) && (( $+commands[wslview] )); then
  alias open='wslview'
elif ! (( ${IS_MAC:-0} )) && (( $+commands[xdg-open] )); then
  alias open='xdg-open'
fi
