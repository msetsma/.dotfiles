# Catppuccin colors for PSReadLine and fzf. Deployed as a dotter template:
# every hex value comes from common/theme/catppuccin-mocha.toml.

$env:FZF_DEFAULT_OPTS = @(
    '--layout=reverse --border=rounded --height=90%'
    '--color=bg+:{{theme.surface0}},bg:{{theme.base}},spinner:{{theme.rosewater}},hl:{{theme.red}}'
    '--color=fg:{{theme.text}},header:{{theme.red}},info:{{theme.mauve}},pointer:{{theme.rosewater}}'
    '--color=marker:{{theme.lavender}},fg+:{{theme.text}},prompt:{{theme.mauve}},hl+:{{theme.red}}'
    '--color=selected-bg:{{theme.surface1}},border:{{theme.overlay0}},label:{{theme.text}}'
) -join ' '

# '#rrggbb' -> truecolor escape; -Background for the 48 (bg) variant
function _hex-color([string]$Hex, [switch]$Background) {
    $r, $g, $b = 1, 3, 5 | ForEach-Object { [Convert]::ToInt32($Hex.Substring($_, 2), 16) }
    "`e[$(if ($Background) { 48 } else { 38 });2;${r};${g};${b}m"
}

if (Get-Module PSReadLine) {
    Set-PSReadLineOption -Colors @{
        Command                = _hex-color '{{theme.blue}}'
        Parameter              = _hex-color '{{theme.flamingo}}'
        Operator               = _hex-color '{{theme.sky}}'
        Variable               = _hex-color '{{theme.lavender}}'
        String                 = _hex-color '{{theme.green}}'
        Number                 = _hex-color '{{theme.peach}}'
        Type                   = _hex-color '{{theme.yellow}}'
        Comment                = _hex-color '{{theme.overlay0}}'
        Keyword                = _hex-color '{{theme.mauve}}'
        Member                 = _hex-color '{{theme.rosewater}}'
        Error                  = _hex-color '{{theme.red}}'
        Emphasis               = _hex-color '{{theme.red}}'
        Default                = _hex-color '{{theme.text}}'
        InlinePrediction       = _hex-color '{{theme.overlay0}}'
        ListPrediction         = _hex-color '{{theme.mauve}}'
        ListPredictionSelected = _hex-color '{{theme.surface0}}' -Background
        Selection              = _hex-color '{{theme.surface2}}' -Background
        ContinuationPrompt     = _hex-color '{{theme.overlay1}}'
    }
}

# Formatted tables and errors
$PSStyle.Formatting.TableHeader = _hex-color '{{theme.mauve}}'
$PSStyle.Formatting.FormatAccent = _hex-color '{{theme.green}}'
$PSStyle.Formatting.Error = _hex-color '{{theme.red}}'
$PSStyle.Formatting.Warning = _hex-color '{{theme.yellow}}'
$PSStyle.Formatting.Verbose = _hex-color '{{theme.overlay1}}'
$PSStyle.Formatting.Debug = _hex-color '{{theme.overlay1}}'
$PSStyle.FileInfo.Directory = _hex-color '{{theme.blue}}'
