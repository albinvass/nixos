{ pkgs, ... }: {
  home.packages = with pkgs; [
    teams
    slack
    discord
    element-desktop
    signal-desktop
    telegram-desktop
  ];
}
