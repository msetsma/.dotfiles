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