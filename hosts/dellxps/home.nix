{ pkgs, homeManagerModules, inputs, ... }:
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
    discord
    bitwarden
    vivaldi
    firefox
    libsForQt5.kwalletmanager
    seahorse
    synergy
    waynergy
    obs-studio
    inputs.git-toprepo.packages.${pkgs.system}.git-toprepo
  ];

  home.sessionVariables = { };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  wezterm = {
    enable_wayland = true;
    dpi = 192;
  };
}
