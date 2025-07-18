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
        vivaldi
      ];
  };

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
}
