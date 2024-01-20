# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ pkgs, ... }:
{

  wsl.enable = true;
  wsl.defaultUser = "avass";
  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;
  users.users.avass = {
    shell = pkgs.zsh;
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
  environment.sessionVariables = {
    BROWSER = "/mnt/c/Windows/explorer.exe";
  };

  # Add compatibility for /bin/bash etc.
  services.envfs.enable = true;
}
