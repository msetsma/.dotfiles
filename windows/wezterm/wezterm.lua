local wezterm = require('wezterm')
local K = require('keybinds')
local F = require('functions')
local config = wezterm.config_builder()

local custom = {
    username = os.getenv('USER') or os.getenv('LOGNAME') or os.getenv('USERNAME'),
    hostname = {
        current = string.lower(wezterm.hostname()),
    },
}

-- Launch
config.default_prog = F.get_default_program()
config.automatically_reload_config = true

-- Colors
config.color_scheme = 'Tokyo Night Storm (Gogh)'
local color_table = wezterm.color.get_builtin_schemes()[config.color_scheme]
wezterm.GLOBAL.color_table = color_table
config.colors = {
    compose_cursor = color_table.ansi[2],
    cursor_bg = color_table.indexed[16] or color_table.ansi[2],
    tab_bar = {
        background = color_table.background,
        active_tab = { bg_color = color_table.background, fg_color = color_table.foreground },
        inactive_tab = { bg_color = color_table.background, fg_color = color_table.foreground },
        inactive_tab_hover = { bg_color = color_table.background, fg_color = color_table.foreground },
        inactive_tab_edge = color_table.background,
        new_tab = { bg_color = color_table.ansi[1], fg_color = color_table.foreground },
        new_tab_hover = { bg_color = color_table.ansi[1], fg_color = color_table.ansi[2], intensity = 'Bold' },
    },
}
config.window_frame = {
    font = wezterm.font({ family = 'JetBrains Mono', weight = 'Bold' }),
    font_size = 10.0,
    active_titlebar_bg = color_table.background,
    inactive_titlebar_bg = color_table.background,
}

-- Window
config.max_fps = 144
config.adjust_window_size_when_changing_font_size = false
config.text_background_opacity = 1.0
config.window_background_opacity = 0.99
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.integrated_title_button_alignment = 'Right'
config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}

-- Font
config.font_size = F.get_os_font_size()

-- Scrolling
config.enable_scroll_bar = false
config.scrollback_lines = 10000

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = true
config.show_tab_index_in_tab_bar = true
config.show_tabs_in_tab_bar = true
config.show_close_tab_button_in_tabs = false
config.status_update_interval = 500
config.use_fancy_tab_bar = true

-- Keys
config.enable_kitty_keyboard = true
config.disable_default_key_bindings = true
config.keys = K.keybinds()

-- Events
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

return config
