$env.config.keybindings ++= [
  {
    name: reload_nu
    modifier: control
    keycode: char_r
    mode: [emacs vi_insert]
    event: {
      send: executehostcommand
      cmd: 'source $nu.config-path'
    }
  },

  {
    name: copy_to_end
    modifier: alt
    keycode: char_e
    mode: [emacs vi_insert]
    event: {
      send: executehostcommand
      cmd: 'echo $(line | str slice $cursor-end) | clip'
    }
  }
]
