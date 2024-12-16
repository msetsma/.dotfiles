local wezterm = require 'wezterm'

-- Return the list of key bindings
return {
    {
        key = "n",
        mods = "CTRL",
        action = wezterm.action.ToggleFullScreen,
    },
    -- Close the current pane
    {
        key = "e",
        mods = "CTRL",
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
        mods = "CTRL",
        action = wezterm.action.ActivateTabRelative(1),
    },
    {
        key = "Tab",
        mods = "CTRL|SHIFT",
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
        mods = "CTRL",
        action = wezterm.action.DecreaseFontSize,
    },
    {
        key = "-",
        mods = "CTRL|SHIFT",
        action = wezterm.action.IncreaseFontSize,
    },
}
