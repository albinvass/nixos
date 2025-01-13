{ pkgs, ... }:
{
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "se";
      variant = "";
    };
  };


  services.xserver.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.gnome.gnome-keyring.enable = true;
  programs.hyprland.enable = true;

  hardware.brillo.enable = true;
  security.pam.services.swaylock = { };
}
