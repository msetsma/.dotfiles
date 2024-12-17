source-env ~/.config/nushell/env.nu
source ~/.config/nushell/aliases.nu
source ~/.config/nushell/functions.nu
$env.config.history.file_format = "sqlite"
$env.config.history.max_size = 5_000_000
$env.config.history.isolation = true
$env.config.show_banner = false
$env.config.completions.algorithm = "fuzzy"
$env.config.completions.sort = "smart"
$env.config.completions.case_sensitive = false 
$env.config.completions.quick = true
$env.config.completions.partial = true
$env.config.completions.use_ls_colors = true
$env.config.completions.external.enable = true
$env.config.completions.external.max_results = 50
$env.config.use_kitty_protocol = true
$env.config.shell_integration.osc2 = true
$env.config.shell_integration.osc7 = true
$env.config.shell_integration.osc9_9 = true
$env.config.shell_integration.osc133 = false # not working with Wezterm on windows as of 
$env.config.shell_integration.osc633 = true
$env.config.bracketed_paste = false
$env.config.use_ansi_coloring = true
$env.config.error_style = "fancy"
$env.config.display_errors.exit_code = false
$env.config.display_errors.termination_signal = true
$env.config.footer_mode = 25
$env.config.table.mode = "rounded"
$env.config.table.index_mode = "always"
$env.config.table.show_empty = true
$env.config.table.padding.left = 1
$env.config.table.padding.right = 1
$env.config.table.header_on_separator = false
$env.config.table.footer_inheritance = false
$env.config.datetime_format.table = null
$env.config.filesize.metric = true
$env.config.float_precision = 2
use ~/.cache/starship/init.nu