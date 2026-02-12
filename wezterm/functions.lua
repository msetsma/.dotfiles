local F = {}
local wezterm = require("wezterm")
local nerdfonts = wezterm.nerdfonts
local mux = wezterm.mux

function F.get_color_or_default(colors , index, fallback)
    if colors.indexed and colors.indexed[index] then
        return colors.indexed[index]
    end
    return fallback
end


function F.path(...)
	local is_windows = wezterm.target_triple:find("windows") ~= nil
	local separator = is_windows and "\\" or "/"
    local parts = { ... }
    return table.concat(parts, separator)
end

function F.normalize_path(path)
    local n_path = path:gsub("\\", "/")
	if n_path:match("^/") then
		n_path = n_path:sub(2)
	end
	return n_path
end

function F.file_exists(name)
	local file = io.open(name, "r")
	if file ~= nil then
		io.close(file)
		return true
	else
		return false
	end
end

function F.scheme_for_appearance(appearance, dark, light)
	if appearance:find("Dark") then
		return dark
	else
		return light
	end
end

function F.basename(string)
	return string.gsub(string, "(.*[/\\])(.*)", "%2")
end

function F.tab_title(tab)
	local title = tab.tab_title
	-- if the tab title is explicitly set, take that
	if title and #title > 0 then
		return title
	end
	-- Otherwise, use the title from the active pane in that tab
	return F.basename(tab.active_pane.title)
end

function F.get_tab_title(tab, tabs, colors)
	local pane = tab.active_pane
	local inactive_title = F.tab_title(tab)
	local active_title = F.tab_title(tab)
	local tab_number = tostring(tab.tab_index + 1)
    local is_last_tab = (tab.tab_index + 1 == #tabs)

	if pane.is_zoomed then
		active_title = nerdfonts.cod_zoom_in .. " " .. active_title
	end

	if string.find(pane.title, "^Copy mode:") then
		active_title = nerdfonts.md_content_copy .. " " .. active_title
	end

	local optional_end = ""
	if is_last_tab then
		optional_end = nerdfonts.ple_right_half_circle_thick
	end

	if tab.is_active then
		return {
			-- left circle
			{ Background = { Color = colors.ansi[1] } },
            { Foreground = { Color = colors.indexed[16]} },
			{ Text = " " .. tab_number .. " " .. active_title .. " "},
			-- optional 
            { Foreground = { Color = colors.ansi[1] } },
			{ Background = { Color = colors.background } },
			{ Text = optional_end },
		}
	else
		return {
			-- tab text
			{ Background = { Color = colors.ansi[1] } },
            { Foreground = { Color = colors.foreground } },
			{ Text = " " .. tab_number .. " " ..  inactive_title .. " " },
			-- optional 
            { Foreground = { Color = colors.ansi[1] } },
			{ Background = { Color = colors.background } },
			{ Text = optional_end },
		}
	end
end

function F.set_tab_bar_status(window, pane, colors, custom)
	local stat = window:active_workspace()
	local workspace_color = colors.ansi[3]
	local time = wezterm.strftime("%H:%M %m/%d")

	if window:active_key_table() then
		stat = window:active_key_table()
		workspace_color = colors.ansi[4]
	elseif window:leader_is_active() then
		stat = "leader"
		workspace_color = colors.ansi[2]
	end

	-- Current working directory
	local cwd = pane:get_current_working_dir()
	if cwd then
		if type(cwd) == "userdata" and cwd.path then
			local path = F.normalize_path(cwd.path)
			local home_dir = F.normalize_path(wezterm.home_dir)

			if path:sub(1, #home_dir) == home_dir then
				path = "~" .. path:sub(#home_dir + 1)
			end
			if #path > 32 then
				cwd = ".." .. path:sub(-32)
			else
				cwd = path
			end
		else
			cwd = tostring(cwd)
		end
	else
		cwd = ""
	end

	-- Left status (left of the tab line)
	window:set_left_status(wezterm.format({
		-- workspace/mux
		{ Background = { Color = colors.background }                },
		{ Text       = " "                                          },
		{ Background = { Color = colors.background }                },
		{ Foreground = { Color = workspace_color }                  },
		{ Text       = nerdfonts.ple_left_half_circle_thick         },
		{ Background = { Color = workspace_color }                  },
		{ Foreground = { Color = colors.ansi[1] }                   },
		{ Text       = nerdfonts.cod_terminal_tmux .. " "           },
		{ Background = { Color = colors.ansi[1] }                   },
		{ Foreground = { Color = colors.foreground }                },
		{ Text       = " " .. stat                                  },
		{ Background = { Color = colors.background }                },
		{ Foreground = { Color = colors.ansi[1] }                   },
		{ Text       = nerdfonts.ple_right_half_circle_thick .. " " },
		-- start of tabs
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = colors.ansi[8] } },
		{ Text = nerdfonts.ple_left_half_circle_thick },
		-- tab icon
		{ Foreground = { Color = colors.background } },
		{ Background = { Color = colors.ansi[8] } },
		{ Text = nerdfonts.oct_terminal .. " " },
	}))

	-- Right status
	window:set_right_status(wezterm.format({
		-- path
		{ Text = " " },
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = colors.ansi[5] } },
		{ Text = nerdfonts.ple_left_half_circle_thick },
		{ Background = { Color = colors.ansi[5] } },
		{ Foreground = { Color = colors.background } },
		{ Text = nerdfonts.md_folder .. " " },
		{ Background = { Color = colors.ansi[1] } },
		{ Foreground = { Color = colors.foreground } },
		{ Text = " " .. cwd },
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = colors.ansi[1] } },
		{ Text = nerdfonts.ple_right_half_circle_thick },
		-- user
		{ Text = " " },
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = colors.ansi[6] } },
		{ Text = nerdfonts.ple_left_half_circle_thick },
		{ Background = { Color = colors.ansi[6] } },
		{ Foreground = { Color = colors.background } },
		{ Text = nerdfonts.fa_user .. " " },
		{ Background = { Color = colors.ansi[1] } },
		{ Foreground = { Color = colors.foreground } },
		{ Text = " " .. custom.username },
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = colors.ansi[1] } },
		{ Text = nerdfonts.ple_right_half_circle_thick },
		-- host device
		{ Text = " " },
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = colors.ansi[7] } },
		{ Text = nerdfonts.ple_left_half_circle_thick },
		{ Background = { Color = colors.ansi[7] } },
		{ Foreground = { Color = colors.ansi[1] } },
		{ Text = nerdfonts.cod_server .. " " },
		{ Background = { Color = colors.ansi[1] } },
		{ Foreground = { Color = colors.foreground } },
		{ Text = " " .. custom.hostname.current },
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = colors.ansi[1] } },
		{ Text = nerdfonts.ple_right_half_circle_thick },
		-- date
		{ Text = " " },
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = colors.ansi[8] } },
		{ Text = nerdfonts.ple_left_half_circle_thick },
		{ Background = { Color = colors.ansi[8] } },
		{ Foreground = { Color = colors.background } },
		{ Text = nerdfonts.md_calendar_clock .. " " },
		{ Background = { Color = colors.ansi[1] } },
		{ Foreground = { Color = colors.foreground } },
		{ Text = " " .. time },
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
			tonumber(string.format("%.2f", window:get_config_overrides().text_background_opacity))
		overrides.window_background_opacity =
			tonumber(string.format("%.2f", window:get_config_overrides().window_background_opacity))
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
			tonumber(string.format("%.2f", window:get_config_overrides().text_background_opacity))
		overrides.window_background_opacity =
			tonumber(string.format("%.2f", window:get_config_overrides().window_background_opacity))
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

function F.init_default_workspaces(projects)
	for _, project in pairs(projects.repositories) do
		 -- Create workspace and tab
		 if project.tabs then
			local _, _, window = mux.spawn_window({ workspace = project.workspace, cwd = F.path(project.path, project.tabs[1]) })
			window:active_tab():set_title(project.name)

			for tab = 2, #project.tabs do
				window:spawn_tab({ cwd = F.path(project.path, project.tabs[tab]) })
			end
		else
			-- Create workspace
			local _, _, window = mux.spawn_window({ workspace = project.workspace, cwd = project.path })
			window:active_tab():set_title(project.name)
		end
	end
	-- Set default workspace
	mux.set_active_workspace(projects.default_workspace)
end

function F.get_process_icon(tab)
	-- ([^/\\]+)%.exe$: Extracts the file name without the .exe extension if the path ends in .exe.
    -- ([^/\\]+)$: Extracts the file name as-is if it doesn't end in .exe.
	local process_name = tab.active_pane.foreground_process_name:match("([^/\\]+)%.exe$")
		or tab.active_pane.foreground_process_name:match("([^/\\]+)$")
	print(process_name)
	local process_icons = { -- for get_process function
		["docker"] = wezterm.nerdfonts.linux_docker,
		["docker-compose"] = wezterm.nerdfonts.linux_docker,
		["nvim"] = wezterm.nerdfonts.custom_vim,
		["make"] = wezterm.nerdfonts.seti_makefile,
		["vim"] = wezterm.nerdfonts.dev_vim,
		["go"] = wezterm.nerdfonts.seti_go,
		["zsh"] = wezterm.nerdfonts.dev_terminal,
		["bash"] = wezterm.nerdfonts.cod_terminal_bash,
		["btm"] = wezterm.nerdfonts.mdi_chart_donut_variant,
		["cargo"] = wezterm.nerdfonts.dev_rust,
		["sudo"] = wezterm.nerdfonts.fa_hashtag,
		["git"] = wezterm.nerdfonts.dev_git,
		["lua"] = wezterm.nerdfonts.seti_lua,
		["gh"] = wezterm.nerdfonts.dev_github_badge,
		["node"] = wezterm.nerdfonts.dev_nodejs_small,
	}

	-- local icon = process_icons[process_name] or string.format('[%s]', process_name)
	local icon = process_icons[process_name] or wezterm.nerdfonts.seti_checkbox_unchecked

	return icon
end

return F
