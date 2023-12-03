{ pkgs, ... }: {
  home.packages = with pkgs; [
    slack
    discord
    element-desktop
    signal-desktop
    telegram-desktop
  ];
}
