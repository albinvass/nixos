{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    home-manager.url = "github:nix-community/home-manager";
  };
  outputs = { self, nixpkgs, ... }@attrs:
  let
    system = "x86_64-linux";
    pkgs = import  nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.albinvass-dellxps = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./laptop/configuration.nix
	self.nixosModule.i3
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
