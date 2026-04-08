local wezterm = require 'wezterm'
local options = require 'options'
local config = wezterm.config_builder()

config.window_background_opacity = 0.99
config.hide_tab_bar_if_only_one_tab = true
config.font = wezterm.font('FiraCode Nerd Font')
config.adjust_window_size_when_changing_font_size = false
config.font_size = options.font_size
config.color_scheme = "Catppuccin Mocha"
--config.window_decorations = "NONE"

config.mouse_bindings = {{
  event = { Down = { streak = 3, button = 'Left' } },
  action = wezterm.action.SelectTextAtMouseCursor 'SemanticZone',
  mods = 'NONE',
}}
config.keys = {
  {
    key = 'n',
    mods = 'SUPER',
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = 'w',
    mods = 'SUPER',
    action = wezterm.action.DisableDefaultAssignment,
  },
}

-- Attach to an existing tmux session if available, otherwise create a new one
-- Never attaches to the "scratch" session
wezterm.on('gui-startup', function(cmd)
  local args = cmd and cmd.args or nil
  if args == nil then
    local success, stdout, _ = wezterm.run_child_process({
      options.default_prog, 'list-sessions', '-F', '#{session_name}'
    })
    if success then
      for name in stdout:gmatch('[^\n]+') do
        if name ~= 'scratch' then
          args = { options.default_prog, 'attach', '-t', name }
          break
        end
      end
    end
    if args == nil then
      args = { options.default_prog, 'new-session', '-s', 'main' }
    end
  end
  local tab, pane, window = wezterm.mux.spawn_window({ args = args })
  if options.fullscreen then
    window:gui_window():toggle_fullscreen()
  end
end)


config.enable_wayland = options.enable_wayland
config.audible_bell = "Disabled"
return config
