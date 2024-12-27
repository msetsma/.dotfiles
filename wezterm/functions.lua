local wezterm = require 'wezterm'

-- Function to reload WezTerm configuration
local function reload_wezterm()
  wezterm.log_info("Reloading WezTerm configuration...")
  wezterm.action.ReloadConfiguration()
end

return {
  reload = reload_wezterm,
}
