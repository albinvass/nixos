{ pkgs, inputs }: (self: super: pkgs.callPackage ./packages.nix { inherit inputs; })
