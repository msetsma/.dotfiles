local wezterm = require("wezterm")
local F = require("functions")
local action = wezterm.action
local OS_MOD = F.get_os_mod()

local K = {}

function K.keybinds(custom)
	return {
		-- Clipboard Operations
		{ key = "c", mods = "CTRL", action = wezterm.action.CopyTo("Clipboard") },
		{ key = "v", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard") },

		-- Wezterm
		{ key = "p", mods = "LEADER", action = action.ActivateCommandPalette },
		{ key = "q", mods = "LEADER", action = action.QuitApplication },

		-- Search
		{ key = "/", mods = "LEADER", action = action.Search({ CaseInSensitiveString = "" }) },

		-- Font Size Adjustments
		{ key = "0", mods = "CTRL", action = action.ResetFontSize },
		{ key = "-", mods = "CTRL", action = action.DecreaseFontSize },
		{ key = "_", mods = "CTRL|SHIFT", action = action.IncreaseFontSize },

		-- Opacity Controls
		{ key = "0", mods = "ALT", action = action.EmitEvent("opacity-reset") },
		{ key = "-", mods = "ALT", action = action.EmitEvent("opacity-decrease") },
		{ key = "_", mods = "ALT|SHIFT", action = action.EmitEvent("opacity-increase") },

		-- Signals
		{ key = "Backspace", mods = "CTRL", action = wezterm.action({ SendString = "\x03" }) }, -- Send cancel signal (Ctrl+C)

		-- Tab Management
		{ key = "n", mods = OS_MOD, action = action.SpawnTab("DefaultDomain") },
		{ key = "l", mods = OS_MOD, action = action.ActivateTabRelative(1) }, -- right
		{ key = "h", mods = OS_MOD, action = action.ActivateTabRelative(-1) }, -- left
		{ key = "x", mods = OS_MOD, action = action.CloseCurrentTab({ confirm = false }) },
		{ key = ".", mods = OS_MOD, action = action.ShowLauncherArgs({ flags = "TABS" }) },

		-- Workspace/Mux managment
		{ key = "l", mods = "LEADER", action = action.SwitchWorkspaceRelative(1) },
		{ key = "h", mods = "LEADER", action = action.SwitchWorkspaceRelative(-1) },
		{ key = "r", mods = "LEADER", action = F.rename_workspace() },
		{ key = "w", mods = "LEADER", action = F.show_workspace_launcher_action() },
		{ key = "x", mods = "LEADER", action = wezterm.action_callback(F.close_workspace) },
		{ key = ".", mods = "LEADER", action = action.ShowLauncherArgs({ flags = "WORKSPACES" }) },
		{ key = "n", mods = "LEADER", action = F.new_workspace() },

		-- Key Tables
		{
			key = "m",
			mods = "LEADER",
			action = action.ActivateKeyTable({
				name = "move",
				one_shot = false,
			}),
		},
		{
			key = "s",
			mods = "LEADER",
			action = action.ActivateKeyTable({
				name = "split",
				one_shot = true,
				until_unknown = true,
				timeout_milliseconds = custom.timeout.key,
			}),
		},
		{
			key = "t",
			mods = "LEADER",
			action = action.ActivateKeyTable({
				name = "tabs",
				one_shot = false,
			}),
		},
		{
			key = "w",
			mods = "LEADER",
			action = action.ActivateKeyTable({
				name = "windows",
				one_shot = false,
			}),
		},
		{
			key = "c",
			mods = "LEADER",
			action = action.ActivateKeyTable({
				name = "commands",
				one_shot = true,
				until_unknown = true,
				timeout_milliseconds = custom.timeout.key,
			}),
		},
	}
end

-- TODO: neovim and wezterm keytables have some issues.
function K.tables()
	return {
		commands = {},
		move = {
			{ key = "s", action = action.PaneSelect },
			{ key = "r", action = action.RotatePanes("CounterClockwise") },
			{ key = "h", action = action.MoveTabRelative(-1) },
			{ key = "l", action = action.MoveTabRelative(1) },
			{ key = "Escape", action = "PopKeyTable" },
		},
		panes = {
			{ key = "h", action = action.ActivatePaneDirection("Left") },
			{ key = "j", action = action.ActivatePaneDirection("Down") },
			{ key = "k", action = action.ActivatePaneDirection("Up") },
			{ key = "l", action = action.ActivatePaneDirection("Right") },
			{ key = "Escape", action = "PopKeyTable" },
		},
		split = {
			{ key = "h", action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
			{ key = "v", action = action.SplitVertical({ domain = "CurrentPaneDomain" }) },
		},
		windows = {
			{ key = "UpArrow", action = action.AdjustPaneSize({ "Up", 1 }) },
			{ key = "DownArrow", action = action.AdjustPaneSize({ "Down", 1 }) },
			{ key = "LeftArrow", action = action.AdjustPaneSize({ "Left", 1 }) },
			{ key = "RightArrow", action = action.AdjustPaneSize({ "Right", 1 }) },
			{ key = "Escape", action = "PopKeyTable" },
		},
	}
end

return K
