local wezterm = require('wezterm')
local K = require('keybinds')
local F = require('functions')
local config = wezterm.config_builder()

local custom = {
    username = os.getenv('USER') or os.getenv('LOGNAME') or os.getenv('USERNAME'),
    hostname = {
        current = string.lower(wezterm.hostname()),
        work = 'pc-xxxxxx',
    },
    timeout = {
        key = 2000,
        leader = 3000,
    },
    default_workspaces = {
        default = 'main',
        repositories = {
            { name = 'home', path = wezterm.home_dir },
            { name = 'dotfiles', path = F.path(wezterm.home_dir, '.dotfiles') },
        },
    },
}

-- Launch
config.default_prog = { F.get_default_program() }
config.automatically_reload_config = true

-- Colors
config.color_scheme = 'Tokyo Night Storm (Gogh)'
local color_table = wezterm.color.get_builtin_schemes()[config.color_scheme]
wezterm.GLOBAL.color_table = color_table -- for tab bar formatting
config.colors = {
    compose_cursor = color_table.ansi[2],
    cursor_bg = color_table.indexed[16] or color_table.ansi[2],
    split = color_table.indexed[16] or color_table.ansi[2],
    tab_bar = { background = color_table.background },
}

-- Window
config.native_macos_fullscreen_mode = false
config.max_fps = 144
config.macos_window_background_blur = 20
config.adjust_window_size_when_changing_font_size = false
config.text_background_opacity = 1.0
config.window_background_opacity = 0.9
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}
config.inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.9,
}

-- Font & ligatures
config.font = wezterm.font('FiraCode Nerd Font', { weight = 'Medium' })
config.font_size = F.get_os_font_size()

-- Scrolling
config.enable_scroll_bar = false
config.scrollback_lines = 10000

-- Tab
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.show_tab_index_in_tab_bar = true
config.status_update_interval = 500
config.tab_max_width = 64
config.use_fancy_tab_bar = false

-- Keys Mapping
config.enable_kitty_keyboard = true
config.disable_default_key_bindings = true
config.leader = { key = 'Delete', timeout_milliseconds = custom.timeout.leader }
config.key_tables = K.tables()
config.keys = K.keybinds(custom)

wezterm.on('update-status', function(window, pane)
    F.set_tab_bar_status(window, pane, custom)
end)

wezterm.on('format-tab-title', function(tab, tabs)
    return F.get_tab_title(tab, tabs)
end)

wezterm.on('opacity-decrease', function(window, _)
    F.lower_opacity(window, config)
end)

wezterm.on('opacity-increase', function(window, _)
    F.increase_opacity(window, config)
end)

wezterm.on('opacity-reset', function(window, _)
    F.reset_opacity(window, config)
end)

wezterm.on('gui-startup', function()
    F.init_default_workspaces(custom.default_workspaces)
end)

return config
