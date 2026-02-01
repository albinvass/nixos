{
  inputs,
  pkgs,
  ...
}:
{
  home = {
    username = "avass";
    homeDirectory = "/home/avass";
    stateVersion = "24.11";
  };
  targets.genericLinux.nixGL = {
    inherit (inputs.nixgl) packages;
    defaultWrapper = "mesa";
    vulkan.enable = true;
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
