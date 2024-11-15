local wezterm = require 'wezterm'
local keybinds = require 'keybinds'
local functions = require 'functions'

local config = wezterm.config_builder()

config.leader = {
    key = "Delete",
    timeout_milliseconds = 3000,
    release_on_activation = true,
}
config.keys = keybinds

config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.default_cursor_style = "BlinkingBar"

-- Font settings
config.font = wezterm.font_with_fallback({
    "FiraCode Nerd Font", -- Main font
    "Noto Color Emoji",   -- Emoji support
})
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
config.font_size = 20
config.color_scheme = 'Aci (Gogh)'
config.hide_tab_bar_if_only_one_tab = false

-- Enable scrollback and history
config.scrollback_lines = 5000

-- Window Settings
config.window_padding = {
    left = 5,
    right = 5,
    top = 5,
    bottom = 5,
}
config.window_background_opacity = 0.95
config.inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.6,
}
config.adjust_window_size_when_changing_font_size = false


return config
