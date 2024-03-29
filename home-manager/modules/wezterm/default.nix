{ config, pkgs, lib, ... }:
{
  options.wezterm = {
    enable_wayland = lib.mkEnableOption "Wezterm for wayland";
    dpi = lib.mkOption {
      default = 96;
      type = lib.types.int;
    };
  };
  config = {
    home.packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
    ];
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = /* lua */ ''
        local config = wezterm.config_builder()
        config.dpi = ${builtins.toString config.wezterm.dpi}
        config.enable_wayland = ${lib.trivial.boolToString(config.wezterm.enable_wayland)}
        config.window_background_opacity = 0.82
        config.hide_tab_bar_if_only_one_tab = true
        config.font = wezterm.font('FiraCode Nerd Font SemBd')
        config.adjust_window_size_when_changing_font_size = false
        config.font_size = 10
        config.color_scheme = "Catppuccin Mocha"
        return config
      '';
    };
  };
}
