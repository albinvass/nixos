{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  options.wezterm = {
    enable_wayland = lib.mkEnableOption "Wezterm for wayland";
  };
  config = {
    home.packages = with pkgs; [ nerd-fonts.fira-code];
    home.file."${config.xdg.configHome}/wezterm" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/git/github/albinvass/nixos/home-manager/modules/wezterm/config";
    };
    # FIX See: https://github.com/nix-community/home-manager/issues/1807#issuecomment-1740960646
    xdg.configFile."wezterm/wezterm.lua".enable = false;
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
