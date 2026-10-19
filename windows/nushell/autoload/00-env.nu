# Environment: editors, tool homes, PATH, telemetry opt-outs.
# Mirrors common/zsh/.zshenv and the PATH block in .zshrc.

use std/util "path add"

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.GOPATH = $nu.home-dir | path join go
$env.BUN_INSTALL = $nu.home-dir | path join .bun
# Keep __pycache__ out of repos (scripts under ~/.config link into .dotfiles)
$env.PYTHONPYCACHEPREFIX = $nu.home-dir | path join .cache python

path add ...([
    ($nu.home-dir | path join .cargo bin)
    ($nu.home-dir | path join .local bin)
    ($env.GOPATH | path join bin)
    ($env.BUN_INSTALL | path join bin)
] | where { path exists })

$env.FZF_DEFAULT_COMMAND = 'rg --files --hidden --glob "!.git"'
$env.FZF_DEFAULT_OPTS = "--layout=reverse --border=rounded --height=90%"

# Telemetry opt-out (keep in sync with common/zsh/.zshenv)
load-env {
    DO_NOT_TRACK: "1"
    DOTNET_CLI_TELEMETRY_OPTOUT: "1"
    NEXT_TELEMETRY_DISABLED: "1"
    ASTRO_TELEMETRY_DISABLED: "1"
    NUXT_TELEMETRY_DISABLED: "1"
    CHECKPOINT_DISABLE: "1"
    GATSBY_TELEMETRY_DISABLED: "1"
    TURBO_TELEMETRY_DISABLED: "1"
    STORYBOOK_DISABLE_TELEMETRY: "1"
    STORYBOOK_ENABLE_CRASH_REPORTS: "0"
    WRANGLER_SEND_METRICS: "false"
    SAM_CLI_TELEMETRY: "0"
    AZURE_CORE_COLLECT_TELEMETRY: "0"
    FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT: "1"
    PP_TOOLS_TELEMETRY_OPTOUT: "1"
    DOTNET_HTTPREPL_TELEMETRY_OPTOUT: "1"
    ALGOLIA_CLI_TELEMETRY: "0"
    GOTELEMETRY: "off"
    AUTOMATEDLAB_TELEMETRY_OPTOUT: "1"
    POWERSHELL_TELEMETRY_OPTOUT: "1"
    OMO_SEND_ANONYMOUS_TELEMETRY: "0"
    DSH_TELEMETRY_DISABLED: "1"
}
