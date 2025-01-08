local wezterm = require("wezterm")
local F = require("functions")
local mux = wezterm.mux
local action = wezterm.action
local K = {}


local function rename_workspace(colors)
	return action.PromptInputLine({
		description = wezterm.format({
			{ Attribute = { Intensity = "Bold" } },
			{ Foreground = { Color = colors.ansi[2] } },
			{ Text = "Enter a new name for the workspace" },
		}),
		action = wezterm.action_callback(function(_, _, line)
			if line then
				mux.rename_workspace(mux.get_active_workspace(), line)
			end
		end),
	})
end

local function new_workspace(colors)
	return action.PromptInputLine {
		description = wezterm.format {
			{ Attribute = { Intensity = 'Bold' } },
			{ Foreground = { Color = colors.ansi[2] } },
			{ Text = 'Enter name for the new workspace' },
		},
		action = wezterm.action_callback(function(window, pane, line)
			if line then
				window:perform_action( action.SwitchToWorkspace { name = line }, pane )
			end
	end) }
end


-- TODO: needs work
local function show_workspace_launcher_action()
	return wezterm.action_callback(function(window, _)
		local workspaces = mux.get_workspace_names()
		local items = {}
		for _, name in ipairs(workspaces) do
			table.insert(items, {
				label = name,
				action = wezterm.action_callback(function()
					mux.set_active_workspace(name)
				end),
			})
		end
		window:show_launcher_menu(items)
	end)
end

function K.keybinds(custom, colors)
	return {
		-- Clipboard Operations
		{ key = "c",         mods = "CTRL",         action = wezterm.action.CopyTo("Clipboard") }, -- Copy to clipboard
		{ key = "v",         mods = "CTRL",         action = wezterm.action.PasteFrom("Clipboard") }, -- Paste from clipboard

		-- Search
		{ key = "/",         mods = "LEADER",       action = action.Search({ CaseInSensitiveString = "" }) }, -- Search with case-insensitive string

		-- Pane Navigation
		{ key = "h",         mods = "ALT",          action = action.ActivatePaneDirection("Left") }, -- Move to the pane to the left
		{ key = "j",         mods = "ALT",          action = action.ActivatePaneDirection("Down") }, -- Move to the pane below
		{ key = "k",         mods = "ALT",          action = action.ActivatePaneDirection("Up") }, -- Move to the pane above
		{ key = "l",         mods = "ALT",          action = action.ActivatePaneDirection("Right") }, -- Move to the pane to the right

		-- Application Control
		{ key = "p",         mods = "LEADER",       action = action.ActivateCommandPalette },
		{ key = "q",         mods = "LEADER",       action = action.QuitApplication },

		-- Font Size Adjustments
		{ key = "0",         mods = "CTRL",         action = action.ResetFontSize }, -- Reset font size
		{ key = "-",         mods = "CTRL",         action = action.DecreaseFontSize }, -- Decrease font size
		{ key = "_",         mods = "CTRL|SHIFT",   action = action.IncreaseFontSize }, -- Increase font size

		-- Opacity Controls
		{ key = "0",         mods = "ALT",          action = action.EmitEvent("opacity-reset") }, -- Reset opacity
		{ key = "-",         mods = "ALT",          action = action.EmitEvent("opacity-decrease") }, -- Decrease opacity
		{ key = "_",         mods = "ALT|SHIFT",    action = action.EmitEvent("opacity-increase") }, -- Increase opacity

		-- Signals
		{ key = "Backspace", mods = "CTRL",         action = wezterm.action({ SendString = "\x03" }) }, -- Send cancel signal (Ctrl+C)

		-- Tab Management
		{ key = "n",         mods = "ALT",          action = action.SpawnTab("DefaultDomain") },
		{ key = "l",         mods = "ALT",          action = action.ActivateTabRelative(1) }, -- Move to right tab
		{ key = "h",         mods = "ALT",          action = action.ActivateTabRelative(-1) }, -- Move to left bab
		{ key = "x",         mods = "ALT",          action = action.CloseCurrentTab { confirm = false } },
		{ key = ".",         mods = "ALT",          action = action.ShowLauncherArgs({ flags = "TABS" }) },

		-- Workspace/Mux managment
		{ key = "l",         mods = "LEADER",       action = action.SwitchWorkspaceRelative(1) },
		{ key = "h",         mods = "LEADER",       action = action.SwitchWorkspaceRelative(-1) },
		{ key = "r",         mods = "LEADER",       action = rename_workspace(colors) },
		{ key = "w",         mods = "LEADER",       action = show_workspace_launcher_action() },
		{ key = "x",         mods = "LEADER",       action = wezterm.action_callback(F.close_workspace) },
		{ key = ".",         mods = "LEADER",       action = action.ShowLauncherArgs({ flags = "WORKSPACES" }) },
		{ key = "n",         mods = "LEADER",       action = new_workspace(colors) },

		-- keytables
		{
			key = "m",
			mods = "LEADER",
			action = action.ActivateKeyTable({
				name = "move",
				one_shot = false,
				until_unknown = false,
				timeout_milliseconds = custom.timeout.key,
			}),
		},
		{
			key = "t",
			mods = "LEADER",
			action = action.ActivateKeyTable({
				name = "resize",
				one_shot = false,
				until_unknown = true,
				timeout_milliseconds = custom.timeout.key,
			}),
		},
		{
			key = "s",
			mods = "LEADER",
			action = action.ActivateKeyTable({
				name = "split",
				one_shot = false,
				until_unknown = true,
				timeout_milliseconds = custom.timeout.key,
			}),
		},
	}
end

function K.tables()
	return {
		move = {
			{ key = "r",                          action = action.RotatePanes("CounterClockwise") },
			{ key = "s",                          action = action.PaneSelect },
			{ key = "Enter",                      action = "PopKeyTable" },
			{ key = "Escape",                     action = "PopKeyTable" },
			{ key = "LeftArrow",  mods = "SHIFT", action = action.MoveTabRelative(-1) },
			{ key = "RightArrow", mods = "SHIFT", action = action.MoveTabRelative(1) },
		},

		resize = {
			{ key = "DownArrow",  action = action.AdjustPaneSize({ "Down", 1 }) },
			{ key = "LeftArrow",  action = action.AdjustPaneSize({ "Left", 1 }) },
			{ key = "RightArrow", action = action.AdjustPaneSize({ "Right", 1 }) },
			{ key = "UpArrow",    action = action.AdjustPaneSize({ "Up", 1 }) },
			{ key = "Enter",      action = "PopKeyTable" },
			{ key = "Escape",     action = "PopKeyTable" },
		},

		split = {
			{ key = "h", mods = "LEADER", action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
			{ key = "v", mods = "LEADER", action = action.SplitVertical({ domain = "CurrentPaneDomain" }) },

		}
	}
end

return K
