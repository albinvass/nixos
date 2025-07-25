{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.albinvass.wezterm;
in
{
  options.albinvass.wezterm = {
    enable = lib.mkEnableOption "Enable Wezterm";
    enable_wayland = lib.mkEnableOption "Wezterm for wayland";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ nerd-fonts.fira-code ];
    home.file."${config.xdg.configHome}/wezterm/wezterm.lua" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/home-manager/modules/wezterm/config/wezterm.lua";
    };
    home.file."${config.xdg.configHome}/wezterm/options.lua" = {
      text = # lua
        ''
          local options = {
            enable_wayland = ${if cfg.enable_wayland then "true" else "false"},
          }

          return options
        '';
    };
    programs.wezterm = {
      enable = true;
      package = (config.lib.nixGL.wrap pkgs.wezterm);
    };
  };
}
