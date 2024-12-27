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

def copy-last-output [] {
    # Get the most recent command from history
    let last_command = (history | last | get command)

    # Re-run the command and capture its output
    let output = ($last_command | eval)

    # Convert the output to text and copy it to the clipboard
    $output | to text | clip
}
