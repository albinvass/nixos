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
        git-toprepo = pkgs.rustPlatform.buildRustPackage {
          pname = "git-toprepo";
          version = "0.1.0";
          src = inputs.git-toprepo;
          cargoLock.lockFile = "${inputs.git-toprepo}/Cargo.lock";
          doCheck = false;
        };
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
