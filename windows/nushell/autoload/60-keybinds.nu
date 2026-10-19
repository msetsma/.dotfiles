# Keybindings, mirroring common/zsh/keybindings.zsh plus the fzf zsh defaults.

def _host-binding [name: string, modifier: string, key: string, cmd: string]: nothing -> record {
    {
        name: $name
        modifier: $modifier
        keycode: $key
        mode: [emacs vi_insert vi_normal]
        event: {send: executehostcommand, cmd: $cmd}
    }
}

$env.config.keybindings ++= [
    (_host-binding cmds_fzf control char_g "cmds")
    (_host-binding line_helper alt char_h "_line-helper")
    (_host-binding fzf_file control char_t "_fzf-insert-file")
    (_host-binding zoxide_pick alt char_c "zi")
]
