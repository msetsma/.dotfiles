local wezterm = require('wezterm')
local action = wezterm.action
local nerdfonts = wezterm.nerdfonts
local mux = wezterm.mux
local F = {}

function F.detect_os()
    local os_name = package.config:sub(1, 1) -- Gets the path separator: '\' for Windows, '/' for Unix-like systems
    if os_name == '\\' then
        return 'windows'
    elseif wezterm.target_triple:find('darwin') then
        return 'macos'
    else
        return 'linux'
    end
end

function F.get_os_font_size()
    local os = F.detect_os()
    if os == 'windows' then
        return 12.0
    elseif os == 'macos' then
        return 16.0
    else
        return 12.0
    end
end

function F.get_default_program()
    local os = F.detect_os()
    if os == 'macos' then
        return 'zsh' --"/Users/M269575/.cargo/bin/nu"
    elseif os == 'linux' then
        return 'nu'
    elseif os == 'windows' then
        return 'nu'
    end
end

function F.path(...)
    local is_windows = wezterm.target_triple:find('windows') ~= nil
    local separator = is_windows and '\\' or '/'
    local parts = { ... }
    return table.concat(parts, separator)
end

function F.normalize_path(path)
    local n_path = path:gsub('\\', '/')
    if n_path:match('^/') then
        n_path = n_path:sub(2)
    end
    return n_path
end

function F.file_exists(name)
    local file = io.open(name, 'r')
    if file ~= nil then
        io.close(file)
        return true
    else
        return false
    end
end

function F.basename(string)
    return string.gsub(string, '(.*[/\\])(.*)', '%2')
end

function F.get_tab_title(tab, tabs)
    local colors = wezterm.GLOBAL.color_table
    local tab_number = tostring(tab.tab_index + 1)
    local is_last_tab = (tab.tab_index + 1 == #tabs)
    local optional_end = ''

    if is_last_tab then
        optional_end = nerdfonts.ple_right_half_circle_thick
    end

    if tab.is_active then
        return {
            -- left circle
            { Background = { Color = colors.ansi[1] } },
            { Foreground = { Color = colors.ansi[2] } },
            { Attribute = { Intensity = 'Bold' } },
            { Text = ' ' .. tab_number .. ' ' },
            -- ending for very last tab
            { Foreground = { Color = colors.ansi[1] } },
            { Background = { Color = colors.background } },
            { Text = optional_end },
        }
    else
        return {
            -- tab text
            { Background = { Color = colors.ansi[1] } },
            { Foreground = { Color = colors.foreground } },
            { Text = ' ' .. tab_number .. ' ' },
            -- ending for very last tab
            { Foreground = { Color = colors.ansi[1] } },
            { Background = { Color = colors.background } },
            { Text = optional_end },
        }
    end
end

function F.set_tab_bar_status(window, pane, custom)
    local colors = wezterm.GLOBAL.color_table
    local stat = window:active_workspace()
    local workspace_color = colors.ansi[3]
    local time = wezterm.strftime('%H:%M %m/%d')

    if window:active_key_table() then
        stat = window:active_key_table()
        workspace_color = colors.ansi[4]
    elseif window:leader_is_active() then
        stat = 'leader'
        workspace_color = colors.ansi[2]
    end

    -- Current worki{ng directory
    local cwd = pane:get_current_working_dir()
    if cwd then
        if type(cwd) == 'userdata' and cwd.path then
            local path = F.normalize_path(cwd.path)
            local home_dir = F.normalize_path(wezterm.home_dir)

            if path:sub(1, #home_dir) == home_dir then
                path = '~' .. path:sub(#home_dir + 1)
            end
            if #path > 32 then
                cwd = '..' .. path:sub(-32)
            else
                cwd = path
            end
        else
            cwd = tostring(cwd)
        end
    else
        cwd = ''
    end

    -- Left status (left of the tab line)
    window:set_left_status(wezterm.format({
        -- workspace/mux
        { Background = { Color = colors.background } },
        { Text = ' ' },
        { Background = { Color = colors.background } },
        { Foreground = { Color = workspace_color } },
        { Text = nerdfonts.ple_left_half_circle_thick },
        { Background = { Color = workspace_color } },
        { Foreground = { Color = colors.ansi[1] } },
        { Text = nerdfonts.cod_terminal_tmux .. ' ' },
        { Background = { Color = colors.ansi[1] } },
        { Foreground = { Color = colors.foreground } },
        { Text = ' ' .. stat },
        { Background = { Color = colors.background } },
        { Foreground = { Color = colors.ansi[1] } },
        { Text = nerdfonts.ple_right_half_circle_thick .. ' ' },
        -- start of tabs
        { Background = { Color = colors.background } },
        { Foreground = { Color = colors.ansi[8] } },
        { Text = nerdfonts.ple_left_half_circle_thick },
        -- tab icon
        { Foreground = { Color = colors.background } },
        { Background = { Color = colors.ansi[8] } },
        { Text = nerdfonts.oct_terminal .. ' ' },
    }))

    -- Right status
    window:set_right_status(wezterm.format({
        -- path
        { Text = ' ' },
        { Background = { Color = colors.background } },
        { Foreground = { Color = colors.ansi[5] } },
        { Text = nerdfonts.ple_left_half_circle_thick },
        { Background = { Color = colors.ansi[5] } },
        { Foreground = { Color = colors.background } },
        { Text = nerdfonts.md_folder .. ' ' },
        { Background = { Color = colors.ansi[1] } },
        { Foreground = { Color = colors.foreground } },
        { Text = ' ' .. cwd },
        { Background = { Color = colors.background } },
        { Foreground = { Color = colors.ansi[1] } },
        { Text = nerdfonts.ple_right_half_circle_thick },
        -- user
        { Text = ' ' },
        { Background = { Color = colors.background } },
        { Foreground = { Color = colors.ansi[6] } },
        { Text = nerdfonts.ple_left_half_circle_thick },
        { Background = { Color = colors.ansi[6] } },
        { Foreground = { Color = colors.background } },
        { Text = nerdfonts.fa_user .. ' ' },
        { Background = { Color = colors.ansi[1] } },
        { Foreground = { Color = colors.foreground } },
        { Text = ' ' .. custom.username },
        { Background = { Color = colors.background } },
        { Foreground = { Color = colors.ansi[1] } },
        { Text = nerdfonts.ple_right_half_circle_thick },
        -- host device
        { Text = ' ' },
        { Background = { Color = colors.background } },
        { Foreground = { Color = colors.ansi[7] } },
        { Text = nerdfonts.ple_left_half_circle_thick },
        { Background = { Color = colors.ansi[7] } },
        { Foreground = { Color = colors.ansi[1] } },
        { Text = nerdfonts.cod_server .. ' ' },
        { Background = { Color = colors.ansi[1] } },
        { Foreground = { Color = colors.foreground } },
        { Text = ' ' .. custom.hostname.current },
        { Background = { Color = colors.background } },
        { Foreground = { Color = colors.ansi[1] } },
        { Text = nerdfonts.ple_right_half_circle_thick },
        -- date
        { Text = ' ' },
        { Background = { Color = colors.background } },
        { Foreground = { Color = colors.ansi[8] } },
        { Text = nerdfonts.ple_left_half_circle_thick },
        { Background = { Color = colors.ansi[8] } },
        { Foreground = { Color = colors.background } },
        { Text = nerdfonts.md_calendar_clock .. ' ' },
        { Background = { Color = colors.ansi[1] } },
        { Foreground = { Color = colors.foreground } },
        { Text = ' ' .. time },
        { Background = { Color = colors.background } },
        { Foreground = { Color = colors.ansi[1] } },
        { Text = nerdfonts.ple_right_half_circle_thick },
    }))
end

function F.reset_opacity(window, config)
    local overrides = window:get_config_overrides() or {}
    overrides.text_background_opacity = config.text_background_opacity
    overrides.window_background_opacity = config.window_background_opacity
    window:set_config_overrides(overrides)
end

function F.lower_opacity(window, config)
    local overrides = window:get_config_overrides() or {}

    if window:get_config_overrides() then
        overrides.text_background_opacity =
            tonumber(string.format('%.2f', window:get_config_overrides().text_background_opacity))
        overrides.window_background_opacity =
            tonumber(string.format('%.2f', window:get_config_overrides().window_background_opacity))
    else
        overrides.text_background_opacity = config.text_background_opacity
        overrides.window_background_opacity = config.window_background_opacity
    end

    if overrides.window_background_opacity > 0 and overrides.window_background_opacity <= 1 then
        overrides.text_background_opacity = overrides.text_background_opacity - 0.05
        overrides.window_background_opacity = overrides.window_background_opacity - 0.05
        window:set_config_overrides(overrides)
    end
end

function F.increase_opacity(window, config)
    local overrides = window:get_config_overrides() or {}

    if window:get_config_overrides() then
        overrides.text_background_opacity =
            tonumber(string.format('%.2f', window:get_config_overrides().text_background_opacity))
        overrides.window_background_opacity =
            tonumber(string.format('%.2f', window:get_config_overrides().window_background_opacity))
    else
        overrides.text_background_opacity = config.text_background_opacity
        overrides.window_background_opacity = config.window_background_opacity
    end

    if overrides.window_background_opacity > 0 and overrides.window_background_opacity <= 1 then
        overrides.text_background_opacity = overrides.text_background_opacity - 0.05
        overrides.window_background_opacity = overrides.window_background_opacity - 0.05
        window:set_config_overrides(overrides)
    end
end

-- set up the default workspaces
function F.init_default_workspaces(workspaces)
    for _, space in pairs(workspaces.repositories) do
        mux.spawn_window({ workspace = space.name, cwd = space.path })
    end
    mux.set_active_workspace(workspaces.default)
end

-- Function to create a new workspace
function F.create_workspace(window, pane)
    window:perform_action(
        action.PromptInputLine({
            description = wezterm.format({
                { Attribute = { Intensity = 'Bold' } },
                { Foreground = { AnsiColor = 'Fuchsia' } },
                { Text = 'Enter name for new workspace' },
            }),
            action = function(user_window, user_pane, line)
                if line and #line > 0 then
                    user_window:perform_action(action.SwitchToWorkspace({ name = line }), user_pane)
                else
                    user_window:toast_notification(
                        'Workspace Creation Cancelled',
                        'No workspace name provided.',
                        nil,
                        3000
                    )
                end
            end,
        }),
        pane
    )
end

-- Function to close the current workspace with confirmation
function F.close_workspace(window, pane)
    window:perform_action(
        wezterm.action.PromptInputLine({
            description = 'Are you sure you want to close this workspace? (yes/no)',
            action = wezterm.action_callback(function(window, _, line)
                if line and line:lower() == 'yes' then
                    local mux_window = window:mux_window()
                    if mux_window then
                        for _, tab in ipairs(mux_window:tabs()) do
                            mux_window:kill_tab(tab)
                        end
                    end
                else
                    window:toast_notification('Workspace Close Cancelled', 'No tabs were closed.', nil, 3000)
                end
            end),
        }),
        pane
    )
end

return F
