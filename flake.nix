{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOs/nixos-hardware/master";
    nixneovimplugins.url = "github:NixNeovim/NixNeovim";
    nix-alien.url = "github:thiagokokada/nix-alien";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
       inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprgrass = {
       url = "github:horriblename/hyprgrass";
       inputs.hyprland.follows = "hyprland";
    };
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
    nwg-displays = {
      url = "github:nwg-piotr/nwg-displays?ref=v0.3.13";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs"; # override this repo's nixpkgs snapshot
    };
  };
  outputs = { self, nixpkgs, ... }@inputs:
  rec {
    nixosConfigurations = 
      let
        hosts = self.lib.getDirectories ./hosts;
        mkNixosConfiguration = host: {
          "${host}" = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./hosts/${host}/configuration.nix ];
            specialArgs = { inherit inputs nixosModules homeManagerModules;};
          };
        };
        nixosConfigurations = nixpkgs.lib.attrsets.mergeAttrsList (builtins.map mkNixosConfiguration hosts);
      in nixosConfigurations;
    nixosModules = self.lib.importModules ./nixos/modules;
    homeManagerModules = self.lib.importModules ./home-manager/modules;
    lib =
      let
        inherit (nixpkgs) lib;
      in rec {
        filterDirectories = files: lib.attrsets.filterAttrs (name: type: type == "directory") files;
        getDirectories = d: (builtins.attrNames (filterDirectories (builtins.readDir d)));
        importModules =
          let
            createModule = name: {
              "${builtins.baseNameOf name}" = import name;
            };
            modules = d: map createModule (map (n: "${builtins.toString d}/${n}") (getDirectories d));
          in d: lib.attrsets.mergeAttrsList (modules d);
      };
  };
}
