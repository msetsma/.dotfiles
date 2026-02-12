local wezterm = require 'wezterm'
local functions = require 'functions'

local mod_key = functions.get_mod_key()

-- Return the list of key bindings
return {
    {
        key = "End",
        mods = mod_key,
        action = wezterm.action_callback(functions.toggle_minimize_restore),
    },
}
