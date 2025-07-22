{
  config,
  pkgs,
  homeManagerModules,
  inputs,
  ...
}:
{
  home = {
    username = "avass";
    homeDirectory = "/home/avass";

    stateVersion = "24.11";

    packages =
      with pkgs;
      let
        s =
          writeShellScriptBin "s" # bash
            ''
              #!${pkgs.bash}/bin/bash
              sudo --preserve-env --preserve-env=PATH env $@
            '';
      in
      [
        s
      ];
  };
  nixGL.packages = inputs.nixgl.packages;
  nixGL.defaultWrapper = "mesa";
  nixGL.vulkan.enable = true;


  xdg.systemDirs.data = [
    "/var/lib/flatpak/exports/share"
    "/home/avass/.local/share/flatpak/exports/share"
  ];


  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
  albinvass = {
    wezterm = {
    enable = true;
    enable_wayland = true;
    };
  };
}
