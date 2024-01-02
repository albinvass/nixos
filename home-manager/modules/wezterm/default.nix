{ ... }:
{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = /* lua */ ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()
      config.enable_wayland = true
      config.dpi = 192.0
      return config
    '';
  };
}
