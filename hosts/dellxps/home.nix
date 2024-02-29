{ pkgs, homeManagerModules, ... }:
{
  imports = [
    ./desktop-files
    homeManagerModules.thunderbird
    homeManagerModules.hyprland
    homeManagerModules.devtools
    homeManagerModules.social-media
    homeManagerModules.music
  ];

  fonts.fontconfig.enable = true;

  xdg.userDirs.enable = true;

  home.username = "avass";
  home.homeDirectory = "/home/avass";
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    bitwarden
    discord
    microsoft-edge
    libsForQt5.kwalletmanager
    gnome.seahorse
    synergy
    waynergy
    obs-studio
  ];

  home.sessionVariables = {};
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
