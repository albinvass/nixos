# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ pkgs, nixosModules, homeManagerModules, inputs, ... }:
{
  imports = [
    inputs.wsl.nixosModules.wsl
    nixosModules.docker
    nixosModules.tailscale
    inputs.home-manager.nixosModules.home-manager
  ];

  system.stateVersion = "23.11";

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ inputs.nixneovimplugins.overlays.default ];
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      extra-substituters = [
        "https://albinvass.cachix.org"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
      ];
      extra-trusted-public-keys = [
        "albinvass.cachix.org-1:9BoW/lEIrRQQt7rnktA3qOg9e9G/Fa2SNwqnUEKq8aM="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.avass = { imports = [ ./home.nix ]; };
    extraSpecialArgs = {
      inherit inputs homeManagerModules;
    };
  };

  wsl = {
    enable = true;
    defaultUser = "avass";
  };

  programs.zsh.enable = true;
  users.users.avass = {
    shell = pkgs.zsh;
  };
  
  environment.sessionVariables = {
    BROWSER = "/mnt/c/Windows/explorer.exe";
  };

  services.envfs.enable = true;
}
