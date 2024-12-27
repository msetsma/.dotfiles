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

# Creates a tree of processes from the ps command.
def "ps tree" [--root-pids (-p): list<int>]: [table -> table,] {
    mut procs = $in

    if $procs == null {
        $procs = ps
    }

    let procs = $procs

    let roots = if $root_pids == null {
        $procs
        | where ppid? == null or ppid not-in $procs.pid
    } else {
        $procs
        | where pid in $root_pids
    }

    $roots
    | insert children {|proc|
        $procs
        | where ppid == $proc.pid
        | each { |child|
            $procs
            | ps tree -p [$child.pid]
            | get 0
        }
    }
}

def get_directories [path: string] {
    ls $path | where type == "dir" | get name
}

# Main command to open a selected website
def offline [] {
    if ($env.OFFLINE_WEBSITES_DIR | is-empty) {
        print "Error: Environment variable OFFLINE_WEBSITES_DIR is not set."
        exit 1
    }

    let base_path = ($env.OFFLINE_WEBSITES_DIR | path expand)
    let websites = get_directories $base_path
    if ( $websites | is-empty) {
        print "Could not find websites."
        exit 1
    }

    let website =  ($websites | input list "select website")
    let index_path = ($base_path | path join $website | path join "index.html")

    if ($index_path | path exists) {
        open $index_path
    } else {
        print "Missing entry point (index.html)"
    }
}