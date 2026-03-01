local wezterm = require('wezterm')
local nerdfonts = wezterm.nerdfonts
local colors = wezterm.GLOBAL.color_table
local F = {}

function F.is_vim(pane)
    return pane:get_user_vars().IS_NVIM == 'true'
end

function F.detect_os()
    local os_name = package.config:sub(1, 1)
    if os_name == '\\' then
        return 'windows'
    elseif wezterm.target_triple:find('darwin') then
        return 'macos'
    end
    return 'linux'
end

function F.get_os_font_size()
    local os = F.detect_os()
    if os == 'windows' then
        return 12.0
    elseif os == 'macos' then
        return 16.0
    end
    return 12.0
end

function F.get_default_program()
    local os = F.detect_os()
    if os == 'windows' then
        return { 'wsl.exe', '--cd', '~' }
    end
    return { 'zsh' }
end

function F.normalize_path(path)
    local n_path = path:gsub('\\', '/')
    if n_path:match('^/') then
        n_path = n_path:sub(2)
    end
    return n_path
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
            { Background = { Color = colors.ansi[1] } },
            { Foreground = { Color = colors.ansi[2] } },
            { Attribute = { Intensity = 'Bold' } },
            { Text = ' ' .. tab_number .. ' ' },
            { Foreground = { Color = colors.ansi[1] } },
            { Background = { Color = colors.background } },
            { Text = optional_end },
        }
    else
        return {
            { Background = { Color = colors.ansi[1] } },
            { Foreground = { Color = colors.foreground } },
            { Text = ' ' .. tab_number .. ' ' },
            { Foreground = { Color = colors.ansi[1] } },
            { Background = { Color = colors.background } },
            { Text = optional_end },
        }
    end
end

function F.set_tab_bar_status(window, pane, custom)
    local time = wezterm.strftime('%H:%M %m/%d')

    -- Current working directory
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

    -- Left status
    window:set_left_status(wezterm.format({
        { Background = { Color = colors.background } },
        { Foreground = { Color = colors.ansi[8] } },
        { Text = ' ' .. nerdfonts.ple_left_half_circle_thick },
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

    if overrides.window_background_opacity >= 0 and overrides.window_background_opacity < 1 then
        overrides.text_background_opacity = overrides.text_background_opacity + 0.05
        overrides.window_background_opacity = overrides.window_background_opacity + 0.05
        window:set_config_overrides(overrides)
    end
end

return F
