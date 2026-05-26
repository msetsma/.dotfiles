local wezterm = require('wezterm')
local K = require('keybinds')
local F = require('functions')
local config = wezterm.config_builder()

-- Launch
config.default_prog = F.get_default_program()
config.automatically_reload_config = true
config.launch_menu = {
    { label = 'WSL (zsh)',          args = { 'wsl.exe', '--cd', '~' } },
    { label = 'Windows PowerShell', args = { 'powershell.exe' } },
}

-- Colors
local color_table = {
    foreground = '#cad3f5',
    background = '#24273a',
    cursor_bg = '#f4dbd6',
    cursor_fg = '#24273a',
    selection_bg = '#5b6078',
    selection_fg = '#cad3f5',
    ansi = {
        '#494d64',
        '#ed8796',
        '#a6da95',
        '#eed49f',
        '#8aadf4',
        '#f5bde6',
        '#8bd5ca',
        '#a5adcb',
    },
    brights = {
        '#5b6078',
        '#ec7486',
        '#8ccf7f',
        '#e1c682',
        '#78a1f6',
        '#f2a9dd',
        '#63cbc0',
        '#b8c0e0',
    },
    indexed = {
        [16] = '#f4dbd6',
        [17] = '#f0c6c6',
    },
}
wezterm.GLOBAL.color_table = color_table
config.colors = {
    compose_cursor = color_table.ansi[2],
    cursor_bg = color_table.cursor_bg,
    cursor_fg = color_table.cursor_fg,
    foreground = color_table.foreground,
    background = color_table.background,
    selection_bg = color_table.selection_bg,
    selection_fg = color_table.selection_fg,
    ansi = color_table.ansi,
    brights = color_table.brights,
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
    active_titlebar_bg = color_table.background,
    inactive_titlebar_bg = color_table.background,
}

-- Window
config.max_fps = 144
config.adjust_window_size_when_changing_font_size = false
config.text_background_opacity = 1.0
config.window_background_opacity = 1.0
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
config.font = wezterm.font_with_fallback {
  'JetBrainsMono Nerd Font',
  'Noto Color Emoji',
}

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
config.use_fancy_tab_bar = true

-- Keys
config.enable_kitty_keyboard = false
config.disable_default_key_bindings = true
config.keys = K.keybinds()

-- Events
wezterm.on('window-config-reloaded', function(window, _)
    F.reset_opacity(window, config)
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
