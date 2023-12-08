{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    nixos-hardware.url = "github:NixOs/nixos-hardware/master";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprgrass = {
       url = "github:horriblename/hyprgrass";
       inputs.hyprland.follows = "hyprland"; # IMPORTANT
    };
    nwg-displays = {
      url = "github:nwg-piotr/nwg-displays?ref=v0.3.9";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-hardware, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
  in rec {
    nixosConfigurations."dellxps" = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./laptop/configuration.nix
        nixosModule.hyprland
        nixosModule.gaming
        nixosModule.docker
        # https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/15-9520
        nixos-hardware.nixosModules.dell-xps-15-9520-nvidia
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.avass = homeManagerModules."avass@dellxps";
          home-manager.extraSpecialArgs = with inputs; { inherit hyprland hyprgrass nwg-displays; };
        }
      ];
    };
    nixosModule = self.lib.importModules ./modules;
    homeManagerModules = {
      "avass@dellxps" = {
        imports = [
          ./laptop/home.nix
          homeManagerModules.hyprland
          homeManagerModules.neovim
          homeManagerModules.zsh
          homeManagerModules.social-media
          homeManagerModules.music
        ];
      };
    } // self.lib.importModules ./home-manager/modules;
    lib = {
      importModules =
        let
          lib = nixpkgs.lib;
          filterDirectories = (files: lib.attrsets.filterAttrs (name: type: type == "directory") files);
          getDirectories = d: map (n: "${builtins.toString d}/${n}") (builtins.attrNames (filterDirectories (builtins.readDir d)));
          createModule = name: {
            "${builtins.baseNameOf name}" = import name;
          };
          modules = d: map createModule (getDirectories d);
        in d: lib.attrsets.mergeAttrsList (modules d);
    };
  };
}
