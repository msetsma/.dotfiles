local wezterm = require("wezterm")
local keybinds = require("keybinds")
local config = wezterm.config_builder()

-- shell settings
config.default_prog = { "nu" }
config.window_close_confirmation = "NeverPrompt"
config.default_cursor_style = "BlinkingBar"
config.automatically_reload_config = true

-- keybinds
config.keys = keybinds
config.leader = {
	key = "Delete",
	timeout_milliseconds = 3000,
	release_on_activation = true,
}

-- font
config.font_size = 12
config.font = (wezterm.font("FiraCode Nerd Font", {weight=450, stretch="Normal", style="Normal"})) -- (AKA: FiraCode Nerd Font Ret))

-- ligatures 
config.harfbuzz_features = {
	'calt',
	'clig',
	'liga',
    'dlig',
	'ss01',
	'ss02',
	'ss03',
	'cv30',
	'cv24',
}

-- window
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.window_decorations = "RESIZE"
config.window_background_opacity = 1.00
config.adjust_window_size_when_changing_font_size = false
config.animation_fps = 144

-- colors
config.color_scheme = 'kanagawabones'
-- wezterm.color.save_scheme("/kanagawabones.toml")

return config

--config.color_scheme= 'Catppuccin Mocha'
--config.color_scheme = 'Aci (Gogh)'
--config.color_scheme = 'BlulocoDark'
--config.color_scheme = 'Canvased Pastel (terminal.sexy)'
--config.color_scheme = "Chameleon (Gogh)"
--config.color_scheme = 'Darktooth (base16)'
