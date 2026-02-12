local wezterm = require 'wezterm'

local M = {}

-- Function to center the terminal window on the primary screen
function M.center_window(window)
  local screen = window:get_primary_screen_size()
  local width = 1600
  local height = 1200
  local x = (screen.width - width) / 2
  local y = (screen.height - height) / 2

  window:perform_action(wezterm.action.MoveWindow {
    x = x,
    y = y,
    width = width,
    height = height
  }, nil)
end

-- Function to determine the mod key based on the operating system
local function M.get_mod_key()
    local target = wezterm.target_triple
    if target:find("darwin") then
      return "CMD"  -- macOS
    else
      return "CTRL" -- Windows and Linux
    end
  end

return M
