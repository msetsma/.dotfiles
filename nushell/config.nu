source-env ~/.config/nushell/env.nu

$env.config.show_banner = false
$env.config.completions.case_sensitive = false 
$env.config.completions.use_ls_colors = true
$env.config.completions.external.enable = true
$env.config.use_kitty_protocol = true
$env.config.shell_integration.osc2 = true
$env.config.shell_integration.osc7 = true
$env.config.shell_integration.osc9_9 = true
$env.config.shell_integration.osc133 = false # not working with Wezterm on windows as of 12-2024 
$env.config.shell_integration.osc633 = true
$env.config.bracketed_paste = false
$env.config.filesize.metric = true

use ~/.cache/starship/init.nu

source ~/.config/zoxide.nu
source ~/.config/nushell/aliases.nu
source ~/.config/nushell/functions.nu
source ~/.config/nushell/keybinds.nu