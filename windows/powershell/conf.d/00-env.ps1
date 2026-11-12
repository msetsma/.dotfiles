# Environment: editors, tool homes, PATH, telemetry opt-outs.
# Mirrors windows/nushell/autoload/00-env.nu.

$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'
$env:GOPATH = Join-Path $HOME 'go'
$env:BUN_INSTALL = Join-Path $HOME '.bun'
# Keep __pycache__ out of repos (scripts under ~/.config link into .dotfiles)
$env:PYTHONPYCACHEPREFIX = Join-Path $HOME '.cache/python'

$pathDirs = @(
    (Join-Path $HOME '.cargo/bin')
    (Join-Path $HOME '.local/bin')
    (Join-Path $env:GOPATH 'bin')
    (Join-Path $env:BUN_INSTALL 'bin')
) | Where-Object { (Test-Path $_) -and ($env:PATH -split ';') -notcontains $_ }
if ($pathDirs) { $env:PATH = ($pathDirs + $env:PATH) -join ';' }
Remove-Variable pathDirs

$env:FZF_DEFAULT_COMMAND = 'rg --files --hidden --glob "!.git"'

# Telemetry opt-out (keep in sync with common/zsh/.zshenv)
@{
    DO_NOT_TRACK                          = '1'
    DOTNET_CLI_TELEMETRY_OPTOUT           = '1'
    NEXT_TELEMETRY_DISABLED               = '1'
    ASTRO_TELEMETRY_DISABLED              = '1'
    NUXT_TELEMETRY_DISABLED               = '1'
    CHECKPOINT_DISABLE                    = '1'
    GATSBY_TELEMETRY_DISABLED             = '1'
    TURBO_TELEMETRY_DISABLED              = '1'
    STORYBOOK_DISABLE_TELEMETRY           = '1'
    STORYBOOK_ENABLE_CRASH_REPORTS        = '0'
    WRANGLER_SEND_METRICS                 = 'false'
    SAM_CLI_TELEMETRY                     = '0'
    AZURE_CORE_COLLECT_TELEMETRY          = '0'
    FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT = '1'
    PP_TOOLS_TELEMETRY_OPTOUT             = '1'
    DOTNET_HTTPREPL_TELEMETRY_OPTOUT      = '1'
    ALGOLIA_CLI_TELEMETRY                 = '0'
    GOTELEMETRY                           = 'off'
    AUTOMATEDLAB_TELEMETRY_OPTOUT         = '1'
    POWERSHELL_TELEMETRY_OPTOUT           = '1'
    OMO_SEND_ANONYMOUS_TELEMETRY          = '0'
    DSH_TELEMETRY_DISABLED                = '1'
}.GetEnumerator() | ForEach-Object { Set-Item "env:$($_.Key)" $_.Value }
