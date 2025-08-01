local wezterm = require 'wezterm'
local options = require 'options'
local config = wezterm.config_builder()

config.window_background_opacity = 0.99
config.hide_tab_bar_if_only_one_tab = true
config.font = wezterm.font('FiraCode Nerd Font SemBd')
config.adjust_window_size_when_changing_font_size = false
config.font_size = 9
config.color_scheme = "Catppuccin Mocha"

config.mouse_bindings = {{
  event = { Down = { streak = 3, button = 'Left' } },
  action = wezterm.action.SelectTextAtMouseCursor 'SemanticZone',
  mods = 'NONE',
}}

config.default_prog = { 'tmux' }


config.enable_wayland = options.enable_wayland
config.audible_bell = "Disabled"
return config
