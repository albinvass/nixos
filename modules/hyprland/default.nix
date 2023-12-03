{ ... }:
{
  services.xserver.displayManager.sddm.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  programs.hyprland.enable = true;
}
