# Create and navigate into a new directory
def mkcd [dir] {
    mkdir $dir
    cd $dir
}

# Search with FZF and change to the selected directory
def fzcd [] {
    let dir = (ls | get name | fzf)
    if $dir != "" {
        cd $dir
    }
}

# Copy input to system clipboard
def "clip copy" []: [string -> nothing] {
    print -n $'(ansi osc)52;c;($in | encode base64)(ansi st)'
}

# Paste contenst of system clipboard
def "clip paste" []: [nothing -> string] {
    try {
        term query $'(ansi osc)52;c;?(ansi st)' -p $'(ansi osc)52;c;' -t (ansi st)
    } catch {
        error make -u {
            msg: "Terminal did not responds to OSC 52 paste request."
            help: $"Check if your terminal supports OSC 52."
        }
    }
    | decode
    | decode base64
    | decode
}