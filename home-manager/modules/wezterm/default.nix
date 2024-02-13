{ ... }:
{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = /* lua */ ''
      local config = wezterm.config_builder()
      config.enable_wayland = true
      config.dpi = 192
      config.window_background_opacity = 0.82
      config.hide_tab_bar_if_only_one_tab = true
      config.font = wezterm.font('FiraCode Nerd Font SemBd')
      config.font_size = 9
      return config
    '';
  };
}
