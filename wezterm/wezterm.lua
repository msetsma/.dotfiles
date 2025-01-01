local wezterm = require("wezterm")
local K = require("keybinds")
local F = require("functions")

local action = wezterm.action
local config = wezterm.config_builder()

-- Custom Themes

-- For loading a local color scheme:
-- local scheme = 'ayu modified'
-- local scheme_def = wezterm.color.load_scheme(wezterm.home_dir .. '/.config/wezterm/colors/<color_scheme>.toml')

-- Color schemes I am testing out:
--config.color_scheme = 'kanagawabones'
--config.color_scheme = 'Catppuccin Mocha'
--config.color_scheme = 'Aci (Gogh)'
--config.color_scheme = 'BlulocoDark'
--config.color_scheme = 'Darktooth (base16)'
--config.color_scheme = "Catppuccin Frappe"

local custom = {
	color_scheme = {
		dark  = "Tokyo Night Moon",
		light = "Catppuccin Mocha",
		fallback = {
			bold = "#a6accd",
			base = "#8c8fa1",
		},
	},
	hostname = {
		current = string.lower(wezterm.hostname()),
		work    = "pc-xxxxxx",
	},
	timeout = {
		key    = 3000,
		leader = 2000,
	},
	username = os.getenv("USER") or os.getenv("LOGNAME") or os.getenv("USERNAME"),
}

-- workspaces / mux
local projects = {
	default_workspace = "default",
	repositories = {
		{ workspace = "default",  name = "main",     path = wezterm.home_dir,                      tabs = { } },
		{ workspace = "dotfiles", name = "dotfiles", path = F.path(wezterm.home_dir, ".dotfiles"), tabs = { 'wezterm', 'nushell' } },
	}
}

-- Path
-- config.set_environment_variables = {
--   PATH = wezterm.home_dir .. ":" .. os.getenv("PATH") .. ":" .. os.getenv("HOME")
-- }

-- Lauching
config.default_prog = { "nu" }
config.automatically_reload_config = true

-- Color Scheme
config.color_scheme = F.scheme_for_appearance(wezterm.gui.get_appearance(), custom.color_scheme.dark, custom.color_scheme.light)
local colors = wezterm.get_builtin_color_schemes()[config.color_scheme]
colors.indexed = colors.indexed or {}
colors.indexed[16] = colors.indexed[16] or colors.ansi[7] or custom.color_scheme.fallback.bold
colors.indexed[17] = colors.indexed[17] or colors.ansi[9] or custom.color_scheme.fallback.base

config.colors = {
	compose_cursor = colors.ansi[2],
	cursor_bg = colors.indexed[16],
	split = colors.indexed[16],
	tab_bar = { background = colors.background },
}

-- Pane
config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.9,
}

-- Window
config.adjust_window_size_when_changing_font_size = false
config.bold_brightens_ansi_colors = true
config.text_background_opacity = 1.0
config.window_background_opacity = 0.98
config.window_decorations = "RESIZE"
config.window_padding = {
	left = 5,
	right = 5,
	top = 5,
	bottom = 5,
}

-- Graphics
config.front_end = wezterm.gui_platform_supports_opengl and "WebGpu" or "Software"
config.webgpu_power_preference = "HighPerformance"
-- "LowPower" - use an integrated GPU
-- "HighPerformance" - use a discrete GPU

-- Cursor
config.bypass_mouse_reporting_modifiers = "SHIFT"
config.default_cursor_style = "BlinkingBar"
config.hide_mouse_cursor_when_typing = false

-- Font & ligatures
config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 10
config.harfbuzz_features = {
	"calt",
	"clig",
	"liga",
	"dlig",
	"ss01",
	"ss02",
	"ss03",
	"cv30",
	"cv24",
}

-- Scrolling
config.enable_scroll_bar                   = false
config.scrollback_lines                    = 10000
config.alternate_buffer_wheel_scroll_speed = 5

-- Tab
config.enable_tab_bar                 = true
config.hide_tab_bar_if_only_one_tab   = false
config.show_new_tab_button_in_tab_bar = false
config.show_tab_index_in_tab_bar      = true
config.status_update_interval         = 1000
config.tab_bar_at_bottom              = false
config.tab_max_width                  = 64
config.use_fancy_tab_bar              = false

-- Keys Mapping
config.disable_default_key_bindings = true
config.leader = { key = "Delete", timeout_milliseconds = custom.timeout.leader }
config.keys = K.keybinds(custom, colors)
config.key_tables = K.tables()

wezterm.on("update-status", function(window, pane)
	F.set_tab_bar_status(window, pane, colors, custom)
end)

wezterm.on("format-tab-title", function(tab, tabs)
	return F.get_tab_title(tab, tabs, colors)
end)

wezterm.on("opacity-decrease", function(window, _)
	F.lower_opacity(window, config)
end)

wezterm.on("opacity-increase", function(window, _)
	F.increase_opacity(window, config)
end)

wezterm.on("opacity-reset", function(window, _)
	F.reset_opacity(window, config)
end)

wezterm.on("gui-startup", function()
	F.init_default_workspaces(projects)
end)

return config
