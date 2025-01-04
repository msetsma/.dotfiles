local wezterm = require('wezterm')
local F = require('functions')
local mux = wezterm.mux
local action = wezterm.action
local K = {}

-- helper functions
local function rename_tab_action(colors)
    return action.PromptInputLine({
        description = wezterm.format({
            { Attribute = { Intensity = 'Bold' } },
            { Foreground = { Color = colors.ansi[8] } },
            { Text = 'Renaming tab title:' },
        }),
        action = wezterm.action_callback(function(window, _, line)
            if line then
                window:active_tab():set_title(line)
            end
        end),
    })
end

local function rename_workspace_action(colors)
    return action.PromptInputLine({
        description = wezterm.format({
            { Attribute = { Intensity = 'Bold' } },
            { Foreground = { Color = colors.ansi[8] } },
            { Text = 'Renaming session/workspace:' },
        }),
        action = wezterm.action_callback(function(_, _, line)
            if line then
                mux.rename_workspace(mux.get_active_workspace(), line)
            end
        end),
    })
end

local function switch_previous_workspace_action()
    return action.Multiple({
        wezterm.action_callback(function(window, pane)
            F.switch_previous_workspace(window, pane)
        end),
        action.EmitEvent('set-previous-workspace'),
    })
end

local function switch_workspace_relative_action(direction)
    return action.Multiple({
        action.SwitchWorkspaceRelative(direction),
        action.EmitEvent('set-previous-workspace'),
    })
end

-- needs work still
local function show_workspace_launcher_action()
    return wezterm.action_callback(function(window, _)
        local workspaces = mux.get_workspace_names()
        local items = {}
        for _, name in ipairs(workspaces) do
            table.insert(items, { label = name, action = wezterm.action_callback(function()
                mux.set_active_workspace(name)
            end) })
        end
        window:show_launcher_menu(items)
    end)
end



function K.keybinds(custom, colors)
	local keybinds = {
		{
			key = 'o',
			mods = 'LEADER',
			action = action.ActivateKeyTable({
				name = 'open',
				one_shot = false,
				until_unknown = true,
				timeout_milliseconds = custom.timeout.key,
			}),
		},
		{
			key = 'm',
			mods = 'LEADER',
			action = action.ActivateKeyTable({
				name = 'move',
				one_shot = false,
				until_unknown = false,
				timeout_milliseconds = custom.timeout.key,
			}),
		},
		{
			key = 'r',
			mods = 'LEADER',
			action = action.ActivateKeyTable({
				name = 'resize',
				one_shot = false,
				until_unknown = true,
				timeout_milliseconds = custom.timeout.key,
			}),
		},

		-- Clipboard Operations
		{ key = 'c', mods = 'CTRL', action = wezterm.action.CopyTo('Clipboard') },    -- Copy to clipboard
		{ key = 'v', mods = 'CTRL', action = wezterm.action.PasteFrom('Clipboard') }, -- Paste from clipboard

		-- Search
		{ key = '/', mods = 'LEADER', action = action.Search({ CaseInSensitiveString = '' }) }, -- Search with case-insensitive string

		-- Split Management
		{ key = '|', mods = 'LEADER|SHIFT', action = action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) }, -- Split pane horizontally
		{ key = '-', mods = 'LEADER', action = action.SplitVertical({ domain = 'CurrentPaneDomain' }) },         -- Split pane vertically

		-- Pane Navigation
		{ key = 'k', mods = 'ALT', action = action.ActivatePaneDirection('Down') },  -- Move to the pane below
		{ key = 'j', mods = 'ALT', action = action.ActivatePaneDirection('Left') },  -- Move to the pane to the left
		{ key = 'l', mods = 'ALT', action = action.ActivatePaneDirection('Right') }, -- Move to the pane to the right
		{ key = 'i', mods = 'ALT', action = action.ActivatePaneDirection('Up') },    -- Move to the pane above

		-- Command Palette
		{ key = 'p', mods = 'LEADER', action = action.ActivateCommandPalette }, -- Open command palette

		-- Application Control
		{ key = 'q', mods = 'LEADER', action = action.QuitApplication }, -- Quit application

		-- Font Size Adjustments
		{ key = '0', mods = 'CTRL',       action = action.ResetFontSize },    -- Reset font size
		{ key = '-', mods = 'CTRL',       action = action.DecreaseFontSize }, -- Decrease font size
		{ key = '_', mods = 'CTRL|SHIFT', action = action.IncreaseFontSize }, -- Increase font size

		-- Opacity Controls
		{ key = '0', mods = 'ALT', action = action.EmitEvent('opacity-reset') },    -- Reset opacity
		{ key = '-', mods = 'ALT', action = action.EmitEvent('opacity-decrease') }, -- Decrease opacity
		{ key = '_', mods = 'ALT|SHIFT', action = action.EmitEvent('opacity-increase') }, -- Increase opacity

		-- Signals
		{ key = 'Backspace', mods = 'CTRL', action = wezterm.action({ SendString = '\x03' }) }, -- Send cancel signal (Ctrl+C)

		-- Tab Management
		{ key = 't', mods = 'ALT',    action = action.SpawnTab('DefaultDomain') },           -- Spawn a new tab
		{ key = 'j', mods = 'ALT',    action = action.ActivateTabRelative(-1) },              -- Move to the previous tab
		{ key = 'l', mods = 'ALT',    action = action.ActivateTabRelative(1) },               -- Move to the next tab
		{ key = 'l', mods = 'ALT',    action = action.ActivateTabRelative(1) },
		{ key = '.', mods = 'ALT',    action = rename_tab_action(colors) },
		{ key = 'w', mods = 'ALT',    action = action.ShowLauncherArgs({ flags = 'TABS' }) }, -- Show launcher (tabs)

		-- Workspace/Mux managment
		{ key = 'Tab', mods = 'CTRL|SHIFT', action = switch_workspace_relative_action(-1) },
		{ key = 'Tab', mods = 'CTRL', action = switch_workspace_relative_action(1) },
		{ key = 'z', mods = 'CTRL|SHIFT', action = switch_previous_workspace_action() },
		{ key = '.', mods = 'CTRL', action = rename_workspace_action(colors) },
		{ key = 'w', mods = 'CTRL', action = show_workspace_launcher_action()}, -- needs work
	}

	-- ALT + N to change tab
	for i = 1, 9 do
		table.insert(keybinds, {
			key = tostring(i),
			mods = 'ALT',
			action = action.ActivateTab(i - 1),
		})
	end

	return keybinds
end

function K.tables()
	return {
		move = {
			{ key = "r", action = action.RotatePanes("CounterClockwise") },
			{ key = "s", action = action.PaneSelect },
			{ key = "Enter", action = "PopKeyTable" },
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "LeftArrow", mods = "SHIFT", action = action.MoveTabRelative(-1) },
			{ key = "RightArrow", mods = "SHIFT", action = action.MoveTabRelative(1) },
		},
	
		resize = {
			{ key = "DownArrow", action = action.AdjustPaneSize({ "Down", 1 }) },
			{ key = "LeftArrow", action = action.AdjustPaneSize({ "Left", 1 }) },
			{ key = "RightArrow", action = action.AdjustPaneSize({ "Right", 1 }) },
			{ key = "UpArrow", action = action.AdjustPaneSize({ "Up", 1 }) },
			{ key = "Enter", action = "PopKeyTable" },
			{ key = "Escape", action = "PopKeyTable" },
		},
	
		open = {
			{
				key = "g",
				action = action({
					QuickSelectArgs = {
						label = "execute 'gcloud auth login --remote-bootstrap'",
						patterns = { 'gcloud auth login --remote-bootstrap=".*"' },
						scope_lines = 30,
						action = action.EmitEvent("trigger-gcloud-auth"),
					},
				}),
			},
			{
				key = "p",
				action = action.SpawnCommandInNewWindow({
					label = "open current path on file manager",
					args = { "xdg-open", "." },
				}),
			},
			{
				key = "u",
				action = action({
					QuickSelectArgs = {
						label = "open URL on browser",
						patterns = { "https?://\\S+" },
						scope_lines = 30,
						action = wezterm.action_callback(function(window, pane)
							local url = window:get_selection_text_for_pane(pane)
							wezterm.log_info("opening: " .. url)
							wezterm.open_with(url)
						end),
					},
				}),
			},
		},
	}
end

return K