# Aliases, mirroring common/zsh/aliases.zsh.
#
# PowerShell aliases cannot carry arguments, so most of these are one-line
# functions. Built-in aliases that collide (cat, ls, gcm, copy) are removed first.

foreach ($name in 'cat', 'ls', 'gcm', 'copy') {
    if (Test-Path "Alias:$name") { Remove-Item "Alias:$name" -Force }
}

# Native commands get "~" verbatim, so expand it for the wrappers below
function _tilde([object[]]$Arguments) {
    foreach ($a in $Arguments) {
        if ($a -is [string] -and ($a -eq '~' -or $a -match '^~[\\/]')) { $HOME + $a.Substring(1) } else { $a }
    }
}

function c { Clear-Host }
function home { Set-Location ~ }
function dotfiles { Set-Location ~/.dotfiles }
function dev { Set-Location ~/dev }
function mlops { Set-Location ~/dev/mlops }

function cat { bat @(_tilde $args) }
function grep { rg @(_tilde $args) }
function find { fd @(_tilde $args) }

$ezaTree = '--icons', '--tree', '--group-directories-first', '-h', '--long', '--no-permissions', '--no-user', '--no-time'
function ls { eza --grid -ah --group-directories-first --git-repos-no-status --icons --all @(_tilde $args) }
function l { eza --grid -ah --group-directories-first --git-repos-no-status --icons --all @(_tilde $args) }
function lt { eza @ezaTree --level=1 @(_tilde $args) }
function lt1 { eza @ezaTree --level=1 @(_tilde $args) }
function lt2 { eza @ezaTree --level=2 @(_tilde $args) }
function lt3 { eza @ezaTree --level=3 @(_tilde $args) }
function lta { eza @ezaTree --total-size @(_tilde $args) }

function gaa { git add . @args }
function gs { git status @args }

function uvt { uv tool @args }
function lzg { lazygit @args }
function lzd { lazydocker @args }
function db { databricks @args }
