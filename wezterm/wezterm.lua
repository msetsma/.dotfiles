local wezterm = require 'wezterm'
local keybinds = require 'keybinds'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.default_prog = {'nu'}
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.default_cursor_style = "BlinkingBar"

-- Font settings
config.font = wezterm.font_with_fallback({
    "FiraCode Nerd Font",        -- Main font
    "Noto Color Emoji",          -- Emoji support
})
-- config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
config.font_size = 10
config.color_scheme = 'Aci (Gogh)'


-- Enable scrollback and history
config.scrollback_lines = 5000

-- Window Settings
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_padding = {
    left = 5,
    right = 5,
    top = 0,
    bottom = 0,
}
config.window_background_opacity = 0.95
config.inactive_pane_hsb = {
    saturation = 0.85,
    brightness = 0.85,
}
config.adjust_window_size_when_changing_font_size = false

-- Keybinds 
config.leader = {
    key = "Delete",
    timeout_milliseconds = 3000,
    release_on_activation = true,
}
config.keys = keybinds

return config
