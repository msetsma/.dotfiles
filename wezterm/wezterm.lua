local wezterm = require 'wezterm'
local keybinds = require 'keybinds'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.default_prog = {'nu'}
config.window_close_confirmation = "NeverPrompt"
config.default_cursor_style = "BlinkingBar"

-- Keybinds 
config.leader = {
    key = "Delete",
    timeout_milliseconds = 3000,
    release_on_activation = true,
}
config.keys = keybinds

-- Font settings
config.font = wezterm.font_with_fallback({
    "FiraCode Nerd Font",
    "Noto Color Emoji", -- Emoji support
})
config.font_size = 12

--config.color_scheme = 'Aci (Gogh)'
config.color_scheme = 'kanagawabones'

-- Window Settings
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.98
config.adjust_window_size_when_changing_font_size = false
config.animation_fps = 144

return config
