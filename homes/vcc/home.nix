{
  config,
  pkgs,
  homeManagerModules,
  inputs,
  ...
}:
{
  imports = [
    #homeManagerModules.wezterm
  ];

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
        bitwarden
        cloak
        dmenu
        ninja
        gcc
        light
        i3
        git-repo
        nixgl.nixGLIntel
        virt-manager
        fly
        arandr
        flameshot
        xclip
        inputs.git-toprepo.packages.${pkgs.system}.git-toprepo
        vivaldi
        feishin
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
  home.file."${config.xdg.configHome}/i3" = {
    source = ./i3;
    recursive = true;
  };
}
