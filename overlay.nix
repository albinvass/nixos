{ pkgs, inputs }: (self: super: import ./packages.nix { inherit inputs  pkgs; })
