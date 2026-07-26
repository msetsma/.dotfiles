# tmux integration: auto-attach new shells and enable tmux-only helpers.

_zsh_tmux_integration_dir="${${(%):-%x}:A:h}"

# Auto-attach interactive shells to tmux. Set TMUX_AUTO_START=0 to bypass.
if [[ -o interactive \
  && -z "${TMUX:-}" \
  && -z "${TMUX_AUTO_STARTED:-}" \
  && "${TMUX_AUTO_START:-1}" != "0" \
  && "${TERM:-}" != "dumb" ]] && (( $+commands[tmux] )); then
  export TMUX_AUTO_STARTED=1
  exec tmux new-session -A -s "${TMUX_AUTO_SESSION:-main}"
fi

[[ -o interactive && -n "${TMUX:-}" ]] && source "$_zsh_tmux_integration_dir/clip.zsh"

unset _zsh_tmux_integration_dir
