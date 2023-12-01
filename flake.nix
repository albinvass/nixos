{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    nixos-hardware.url = "github:NixOs/nixos-hardware/master";
  };
  outputs = { self, nixpkgs, nixos-hardware }:
  let
    system = "x86_64-linux";
    pkgs = import  nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations."dellxps" = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./laptop/configuration.nix
	self.nixosModule.hyprland
	# https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/15-9520
	nixos-hardware.nixosModules.dell-xps-15-9520
      ];
    };
    nixosModule =
      let
        lib = nixpkgs.lib;
        filterDirectories = (files: lib.attrsets.filterAttrs (name: type: type == "directory") files);
        getDirectories = d: builtins.attrNames (filterDirectories (builtins.readDir d));
        createNixosModule = name: {
          ${name} = import ./modules/${name};
        };
        modules = map createNixosModule (getDirectories ./modules);
      in lib.attrsets.mergeAttrsList modules;
  };
}
