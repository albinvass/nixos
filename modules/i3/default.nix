{ pkgs, ... }:
{
  services.xserver.windowManager.i3 = {
    enable = true;
    package = pkgs.i3-gaps;
  };

  programs.i3lock.enable = true;
}
