{ pkgs, ... }:
let
  kubectl-hns = pkgs.callPackage ./kubectl-hns.nix {};
in
{
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    kind
    minikube
    kubelogin
    kubelogin-oidc
    kubectl-hns
  ];
}
