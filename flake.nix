{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    home-manager.url = "github:nix-community/home-manager";
  };
  outputs = { self, nixpkgs, ... }@attrs: {
    nixosConfigurations.albinvass-dellxps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./laptop/configuration.nix ];
    };
  };
}
