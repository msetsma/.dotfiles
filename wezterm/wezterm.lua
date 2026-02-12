local wezterm = require 'wezterm'
local keybinds = require 'keybinds'
local functions = require 'functions'

return {
    keys = keybinds -- keybinds from keybinds.lua
    
    -- Font settings
    font = wezterm.font_with_fallback({
        "Fira Code",        -- Main font
        "Noto Color Emoji", -- Emoji support
    }),
    font_size = 12.5,
    color_scheme = 'Aci (Gogh)',
    hide_tab_bar_if_only_one_tab = true,

    -- Platform-specific configurations
    default_prog = wezterm.target_triple == "x86_64-apple-darwin" and {"/bin/zsh"} or {"/usr/bin/zsh"},

    -- Set the working directory based on platform
    default_cwd = wezterm.target_triple == "x86_64-apple-darwin" and "/Users/your_username" or "/home/your_username",

    -- Enable Scrollback and history
    scrollback_lines = 5000,

    -- Set window padding
    window_padding = {
        left = 5,
        right = 5,
        top = 5,
        bottom = 5,
    },

    -- Enable OpenGL for better performance
    enable_wayland = false,
    use_ime = true, -- for input method support
}