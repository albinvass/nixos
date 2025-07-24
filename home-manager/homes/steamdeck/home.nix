{
  pkgs,
  ...
}:
{
  home = {
    username = "avass";
    homeDirectory = "/home/avass";
    stateVersion = "24.11";
    packages = with pkgs; [
      vivaldi
    ];
  };

  albinvass = {
    chats.enable = true;
    devtools.enable = true;
    wezterm = {
      enable = true;
      enable_wayland = true;
    };
  };
}
