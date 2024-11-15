local wezterm = require 'wezterm'
local functions = require 'functions'

-- Return the list of key bindings
return {
    {
        key = "n",
        mods = "CMD",
        action = wezterm.action.ToggleFullScreen,
    },
    -- Close the current pane
    {
        key = "e",
        mods = "CMD",
        action = wezterm.action.CloseCurrentPane { confirm = false },
    },
    -- Pane navigation
    {
        key = "j",
        mods = "LEADER",
        action = wezterm.action.ActivatePaneDirection "Left",
    },
    {
        key = "k",
        mods = "LEADER",
        action = wezterm.action.ActivatePaneDirection "Down",
    },
    {
        key = "i",
        mods = "LEADER",
        action = wezterm.action.ActivatePaneDirection "Up",
    },
    {
        key = "l",
        mods = "LEADER",
        action = wezterm.action.ActivatePaneDirection "Right",
    },
    {
        key = "Tab",
        mods = "CMD",
        action = wezterm.action.ActivateTabRelative(1),
    },
    {
        key = "Tab",
        mods = "CMD|SHIFT",
        action = wezterm.action.ActivateTabRelative(-1),
    },


    -- Splitting panes in different directions using the leader key
    {
        key = "j",
        mods = "LEADER|SHIFT",
        action = wezterm.action.SplitPane {
            direction = "Left",
            size = { Percent = 50 },
        },
    },
    {
        key = "k",
        mods = "LEADER|SHIFT",
        action = wezterm.action.SplitPane {
            direction = "Down",
            size = { Percent = 50 },
        },
    },
    {
        key = "i",
        mods = "LEADER|SHIFT",
        action = wezterm.action.SplitPane {
            direction = "Up",
            size = { Percent = 50 },
        },
    },
    {
        key = "l",
        mods = "LEADER|SHIFT",
        action = wezterm.action.SplitPane {
            direction = "Right",
            size = { Percent = 50 },
        },
    },

    -- Change font size not window size
    {
        key = "-",
        mods = "CMD",
        action = wezterm.action.DecreaseFontSize,
    },
    {
        key = "-",
        mods = "CMD|SHIFT",
        action = wezterm.action.IncreaseFontSize,
    },
}
