{ config, pkgs, homeManagerModules, ... }:
{
  imports = [
    homeManagerModules.vcc
    homeManagerModules.wezterm
  ];

  home = {
    username = "avass";
    homeDirectory = "/home/avass";

    stateVersion = "23.11";

    packages = with pkgs;
      let
        vpn = writeShellScriptBin "vpn" /* bash */ ''
          #!${pkgs.bash}/bin/bash
          export POINTSHARP_TOKEN="$(${cloak}/bin/cloak view vcc)"
          source-secrets vcc
          vccvpn $@
        '';
        s = writeShellScriptBin "s" /* bash */ ''
          #!${pkgs.bash}/bin/bash
          sudo --preserve-env=PATH env $@
        '';
      in [
        bitwarden
        microsoft-edge
        cloak
        dmenu
        ninja
        gcc
        i3
        git-repo
        nixgl.nixGLIntel
        firecracker
        virt-manager
        fly
      ] ++ [
        vpn
        s
      ];
  };

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
  home.file."${config.xdg.configHome}/i3" = {
    source = ./i3;
    recursive = true;
  };
}
