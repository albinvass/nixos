{ pkgs, ... }:
{
  services.xserver.displayManager.sddm.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  programs.hyprland.enable = true;
  environment.systemPackages = with pkgs; [
    xwaylandvideobridge
    xdg-desktop-portal
    libsForQt5.polkit-kde-agent
  ];
}
