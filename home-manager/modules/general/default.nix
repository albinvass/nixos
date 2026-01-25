{ config, pkgs, ... }:
{
  config = {
    programs.home-manager.enable = true;
    targets.genericLinux.enable = !config.submoduleSupport.enable;
    fonts.fontconfig.enable = true;
    xdg.systemDirs.data =
      if pkgs.stdenv.isLinux then
        [
          "/var/lib/flatpak/exports/share"
          "${config.xdg.dataHome}/flatpak/exports/share"
        ]
      else
        [ ];
  };
}
