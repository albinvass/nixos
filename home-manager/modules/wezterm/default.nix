{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.wezterm = {
    enable_wayland = lib.mkEnableOption "Wezterm for wayland";
  };
  config = {
    home.packages = with pkgs; [ nerd-fonts.fira-code ];
    home.file."${config.xdg.configHome}/wezterm/wezterm.lua" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/git/github/albinvass/nixos/home-manager/modules/wezterm/config/wezterm.lua";
    };
    home.file."${config.xdg.configHome}/wezterm/options.lua" = {
      text = /* lua */ ''
        local options = {
          enable_wayland = ${if config.wezterm.enable_wayland then "true" else "false"},
        }

        return options
      '';
    };
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
      package = (config.lib.nixGL.wrap pkgs.wezterm);
    };
  };
}
