{ inputs, homeManagerModules, ... }:
{
  imports = [
    homeManagerModules.neovim
    homeManagerModules.zsh
    homeManagerModules.git
    homeManagerModules.github
    homeManagerModules.kubernetes
    homeManagerModules.sops
    homeManagerModules.srenity
    inputs.sops-nix.homeManagerModules.sops
  ];
}
