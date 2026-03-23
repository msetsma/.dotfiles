local wezterm = require('wezterm')
local action = wezterm.action

local K = {}

function K.keybinds()
    return {
        -- Clipboard
        { key = 'c', mods = 'CTRL', action = wezterm.action_callback(function(window, pane)
            local has_selection = window:get_selection_text_for_pane(pane) ~= ''
            if has_selection then
                window:perform_action(action.CopyTo('ClipboardAndPrimarySelection'), pane)
                window:perform_action(action.ClearSelection, pane)
            else
                window:perform_action(action.SendKey({ key = 'c', mods = 'CTRL' }), pane)
            end
        end) },
        { key = 'v', mods = 'CTRL', action = action.PasteFrom('Clipboard') },

        -- Window
        { key = 'Enter', mods = 'ALT',       action = action.ShowLauncherArgs({ flags = 'LAUNCH_MENU_ITEMS' }) },
        { key = 'Enter', mods = 'CMD|SHIFT', action = action.ToggleFullScreen },
        { key = 'p', mods = 'ALT', action = action.ActivateCommandPalette },
        { key = 'q', mods = 'ALT', action = action.QuitApplication },

        -- Search
        { key = '/', mods = 'ALT', action = action.Search({ CaseInSensitiveString = '' }) },

        -- Font Size
        { key = '0', mods = 'CTRL', action = action.ResetFontSize },
        { key = '-', mods = 'CTRL', action = action.DecreaseFontSize },
        { key = '_', mods = 'CTRL|SHIFT', action = action.IncreaseFontSize },

        -- Opacity
        { key = '0', mods = 'ALT', action = action.EmitEvent('opacity-reset') },
        { key = '-', mods = 'ALT', action = action.EmitEvent('opacity-decrease') },
        { key = '_', mods = 'ALT|SHIFT', action = action.EmitEvent('opacity-increase') },

        -- Signals
        { key = 'Backspace', mods = 'CTRL', action = action.SendString('\x03') },
    }
end

return K
