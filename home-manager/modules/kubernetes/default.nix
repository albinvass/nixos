{ config, pkgs, lib, ... }:
let
  cfg = config.albinvass.kubernetes;
in
{
  options.albinvass.kubernetes = {
    enable = lib.mkEnableOption "Enable kubernetes configuration";
  };
  config = lib.mkIf cfg.enable {
    home.packages = let
      kubectl-hns = pkgs.callPackage ./kubectl-hns.nix { };
    in with pkgs; [
      kubectl
      kubernetes-helm
      kind
      kubelogin
      kubelogin-oidc
      kubectl-hns
    ];
  };
}
