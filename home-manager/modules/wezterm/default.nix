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
    font_size = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Fontsize";
    };
    default_prog = lib.mkOption {
      type = lib.types.str;
      default = "${config.programs.tmux.package}/bin/tmux";
      description = "Default program for wezterm";
    };
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ nerd-fonts.fira-code ];
    home.file."${config.xdg.configHome}/wezterm/wezterm.lua" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/home-manager/modules/wezterm/config/wezterm.lua";
    };
    home.file."${config.xdg.configHome}/wezterm/options.lua" = {
      text = with cfg; /* lua */ ''
        local options = {
          enable_wayland = ${if enable_wayland then "true" else "false"},
          font_size = ${toString font_size},
          default_prog =  "${default_prog}",
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
