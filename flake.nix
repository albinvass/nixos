{
  inputs = {
    bacon-ls = {
      url = "github:crisidev/bacon-ls";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };
    catppuccin-btop = {
      url = "github:catppuccin/btop";
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
    gerrit-cli = {
      url = "github:stagnation/gerrit-cli";
      flake = false;
    };
    git-toprepo.url = "github:meroton/git-toprepo";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOs/nixos-hardware/master";
    nixneovimplugins.url = "github:NixNeovim/NixNeovim";
    nixgl.url = "github:guibou/nixGL";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
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
    pygerrit2 = {
      url = "github:dpursehouse/pygerrit2";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    {
      formatter = {
        x86_64-linux =
          let
            pkgs = import nixpkgs {
              system = "x86_64-linux";
            };
          in
          pkgs.nixfmt-tree;
        aarch64-darwin =
          let
            pkgs = import nixpkgs {
              system = "aarch64-darwin";
            };
          in
          pkgs.nixfmt-tree;
      };
      overlays.default = {

      };
      nixosConfigurations = {
        "dellxps" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./nixos/hosts/dellxps/configuration.nix
          ];
          specialArgs = {
            inherit inputs;
          };
        };
      };
      darwinConfigurations."Albins-MacBook-Air" = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          inputs.home-manager.darwinModules.home-manager
          ./nix-darwin/configuration.nix
        ];
        specialArgs = {
          inherit inputs;
        };
      };
      homeConfigurations =
        let
          mkHomeManagerBase =
            system: modules:
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
                overlays = [
                  inputs.bacon-ls.overlay.${system}
                ];
              };
              modules = [
                ./home-manager/modules
              ]
              ++ modules;
              extraSpecialArgs = {
                inherit inputs;
              };
            };
        in
        {
          "avass@desktop" = mkHomeManagerBase "x86_64-linux" [
              ./home-manager/homes/desktop/home.nix
            ];
          "avass@steamdeck" = mkHomeManagerBase "x86_64-linux" [
              ./home-manager/homes/steamdeck/home.nix
            ];
          "avass@5CG4420JDB" = mkHomeManagerBase "x86_64-linux" [
              ./home-manager/homes/vcc/home.nix
            ];
          "albin-vass@framework" = mkHomeManagerBase "x86_64-linux" [
              ./home-manager/homes/framework/home.nix
            ];
        };
      lib = import ./lib { inherit (nixpkgs) lib; };
    };
}
