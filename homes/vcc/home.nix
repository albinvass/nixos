{
  pkgs,
  inputs,
  ...
}:
{
  home = {
    username = "avass";
    homeDirectory = "/home/avass";
    sessionPath = [ "$HOME/.local/bin" ];

    stateVersion = "23.11";

    packages =
      with pkgs;
      let
        s =
          writeShellScriptBin "s" # bash
            ''
              #!${pkgs.bash}/bin/bash
              sudo --preserve-env --preserve-env=PATH env "$@"
            '';
        bazel =
          writeShellScriptBin "bazel" # bash
            ''
              #!${pkgs.bash}/bin/bash
              ${pkgs.bazelisk}/bin/bazelisk "$@"
            '';
      in
      [
        git-repo
        nixgl.nixGLIntel
        xclip
        vivaldi
        git-toprepo
      ]
      ++ [
        s
        bazel
      ];
  };
  programs = {
    zellij = {
      settings = {
        copy_command = "xclip -selection clipboard"; # x11
      };
    };
  };

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
}
