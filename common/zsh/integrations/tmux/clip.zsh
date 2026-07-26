# Track the last command's tmux pane range for clip-widget.

autoload -Uz add-zsh-hook

typeset -g __zsh_tmux_clip_command=""
typeset -gi __zsh_tmux_clip_start_line=0
typeset -gi __zsh_tmux_clip_end_line=0
typeset -gi __zsh_tmux_clip_pending=0
typeset -gi __zsh_tmux_clip_ready=0

_zsh_tmux_clip_capture_pane() {
  [[ -n "${TMUX:-}" ]] || return 1
  (( $+commands[tmux] )) || return 1

  local -a target
  [[ -n "${TMUX_PANE:-}" ]] && target=(-t "$TMUX_PANE")

  command tmux capture-pane -p -S - -E - "${target[@]}" 2>/dev/null
}

_zsh_tmux_clip_line_count() {
  local captured_pane
  captured_pane="$(_zsh_tmux_clip_capture_pane)" || return 1

  local -a pane_lines
  pane_lines=("${(@f)captured_pane}")
  print -r -- "${#pane_lines}"
}

_zsh_tmux_clip_preexec() {
  [[ -n "${TMUX:-}" ]] || return 0

  local start_line
  start_line="$(_zsh_tmux_clip_line_count)" || {
    __zsh_tmux_clip_pending=0
    __zsh_tmux_clip_ready=0
    return 0
  }

  __zsh_tmux_clip_command="$1"
  __zsh_tmux_clip_start_line="$start_line"
  __zsh_tmux_clip_end_line=0
  __zsh_tmux_clip_pending=1
  __zsh_tmux_clip_ready=0
}

_zsh_tmux_clip_precmd() {
  (( ${__zsh_tmux_clip_pending:-0} )) || return 0

  local end_line
  end_line="$(_zsh_tmux_clip_line_count)" || {
    __zsh_tmux_clip_pending=0
    __zsh_tmux_clip_ready=0
    return 0
  }

  __zsh_tmux_clip_end_line="$end_line"
  __zsh_tmux_clip_pending=0
  if (( __zsh_tmux_clip_end_line >= __zsh_tmux_clip_start_line )); then
    __zsh_tmux_clip_ready=1
  else
    __zsh_tmux_clip_ready=0
  fi
}

add-zsh-hook -d preexec _zsh_tmux_clip_preexec 2>/dev/null
add-zsh-hook -d precmd _zsh_tmux_clip_precmd 2>/dev/null
add-zsh-hook preexec _zsh_tmux_clip_preexec
add-zsh-hook precmd _zsh_tmux_clip_precmd
