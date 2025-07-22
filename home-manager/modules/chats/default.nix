{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.albinvass.chats;
in
{
  options.albinvass.chats = {
    enable = lib.mkEnableOption "Enable chat applications";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      slack
      discord
      element-desktop
      signal-desktop
    ];
  };
}
