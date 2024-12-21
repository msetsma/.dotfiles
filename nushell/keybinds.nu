$env.config.keybindings ++= [
  {
    name: copy_commandline
    modifier: alt
    keycode: char_c
    mode: [emacs vi_insert]
    event: {
      send: executehostcommand
      cmd: 'commandline | nu-highlight | $"`` `ansi\n($in)\n` ``" | clip copy'
    }
  }
]