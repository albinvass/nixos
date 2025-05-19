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
    home.file."${config.xdg.configHome}/wezterm" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/git/github/albinvass/nixos/home-manager/modules/wezterm/config";
    };
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
