{ pkgs, ... }:
{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "se";
    xkbVariant = "";
  };

  services.xserver.displayManager.sddm.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  programs.hyprland.enable = true;

  hardware.brillo.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
