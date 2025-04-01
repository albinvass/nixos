{
  config,
  pkgs,
  homeManagerModules,
  inputs,
  ...
}:
{
  home = {
    username = "bazzite";
    homeDirectory = "/home/bazzite";

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

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
  programs.zellij = {
    settings = {
      copy_command = "wl-copy";
    };
  };
}
