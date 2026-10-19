# Nushell config (native Windows). Only partial $env.config assignments live
# here; commands, aliases and keybindings are split across autoload/*.nu,
# which nushell sources alphabetically after this file.

$env.config.show_banner = false
$env.config.edit_mode = "emacs"
$env.config.buffer_editor = "nvim"
$env.config.auto_cd_implicit = true
$env.config.footer_mode = "auto"
$env.config.error_style = "fancy"

$env.config.history.file_format = "sqlite"
$env.config.history.max_size = 50_000
$env.config.history.sync_on_enter = true
$env.config.history.isolation = false
$env.config.history.ignore_space_prefixed = true

$env.config.completions.algorithm = "fuzzy"
$env.config.completions.case_sensitive = false

$env.config.cursor_shape.emacs = "line"
$env.config.table.mode = "rounded"
$env.config.table.index_mode = "auto"

# WezTerm on Windows misplaces the prompt after clear when OSC 133 is on.
$env.config.shell_integration.osc133 = false
$env.config.shell_integration.osc7 = true
