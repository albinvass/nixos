{
  inputs = {
    bacon-ls = {
      url = "github:crisidev/bacon-ls";
    };
    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };
    catppuccin-starship = {
      url = "github:catppuccin/starship";
      flake = false;
    };
    catppuccin-yazi = {
      url = "github:catppuccin/yazi";
      flake = false;
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    git-toprepo.url = "github:meroton/git-toprepo";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOs/nixos-hardware/master";
    nixneovimplugins.url = "github:NixNeovim/NixNeovim";
    nixgl.url = "github:guibou/nixGL";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wezterm = {
      url = "github:wez/wezterm?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };
    in
    {
      checks.x86_64-linux = {
        nixfmt = pkgs.stdenv.mkDerivation {
          name = "nixfmt";
          src = ./.;
          doCheck = true;
          dontBuild = true;
          nativeBuildInputs = with pkgs; [ nixfmt-rfc-style ];
          checkPhase = # bash
            ''
              nixfmt --check $(find . -name "*.nix" ! -name "flake.nix")
            '';
          installPhase = ''
            mkdir $out
          '';
        };
      };
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = [ inputs.attic.packages.x86_64-linux.attic-client ];
      };
      packages.x86_64-linux = import ./packages.nix { inherit inputs pkgs; };
      formatter.x86_64-linux = pkgs.nixfmt-tree;
      nixosConfigurations = self.lib.importHosts ./hosts {
        inherit inputs;
        inherit (self) nixosModules overlays;
      };
      nixosModules = self.lib.importModules ./nixos/modules;
      overlays.default = import ./overlay.nix { inherit pkgs inputs; };
      homeConfigurations =
        let
          mkHomeManagerConfiguration =
            host: config:
            pkgs.lib.nameValuePair host (
              inputs.home-manager.lib.homeManagerConfiguration {
                pkgs = import nixpkgs {
                  inherit (config) system;
                  config.allowUnfree = true;
                  overlays = [
                    inputs.bacon-ls.overlay.${config.system}
                    self.overlays.default
                  ];
                };
                modules = [
                  config.home
                  ./home-manager/modules
                ];
                extraSpecialArgs = {
                  inherit inputs;
                };
              }
            );
        in
        pkgs.lib.attrsets.mapAttrs' mkHomeManagerConfiguration {
          "avass@desktop" = {
            system = "x86_64-linux";
            home = ./home-manager/homes/desktop/home.nix;
          };
          "avass@steamdeck" = {
            system = "x86_64-linux";
            home = ./home-manager/homes/steamdeck/home.nix;
          };
          "avass@5CG4420JDB" = {
            system = "x86_64-linux";
            home = ./home-manager/homes/vcc/home.nix;
          };
        };
      lib = import ./lib { inherit (nixpkgs) lib; };
    };
}
