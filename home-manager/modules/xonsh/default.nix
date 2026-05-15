{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.albinvass.xonsh;
in
{
  options.albinvass.xonsh = {
    enable = lib.mkEnableOption "Enable xonsh configuration";
  };
  config = lib.mkIf cfg.enable {
    home.file."${config.xdg.configHome}/xonsh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/home-manager/modules/xonsh/xonsh";
    home.packages = [ pkgs.xonsh ];
  };
}
