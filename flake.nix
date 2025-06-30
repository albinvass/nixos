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
    rec {
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
      formatter.x86_64-linux = pkgs.nixfmt-rfc-style;
      nixosConfigurations = self.lib.importHosts ./hosts {
        inherit inputs;
        inherit (self) nixosModules homeManagerModules overlays;
      };
      nixosModules = self.lib.importModules ./nixos/modules;
      overlays.default = import ./overlay.nix { inherit pkgs inputs; };
      homeManagerModules = self.lib.importModules ./home-manager/modules;
      homeConfigurations."avass@5CG4420JDB" = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs =
          let
            system = "x86_64-linux";
          in
          import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              inputs.nixneovimplugins.overlays.default
              inputs.nixgl.overlay
              inputs.bacon-ls.overlay.${system}
              self.overlays.default
            ];
          };
        modules = [
          ./homes/vcc/home.nix
          homeManagerModules.devtools
          homeManagerModules.chats
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit (self) homeManagerModules;
        };
      };
      homeConfigurations."bazzite" = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [
            inputs.nixneovimplugins.overlays.default
          ];
        };
        modules = [
          ./homes/bazzite/home.nix
          homeManagerModules.devtools
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit (self) homeManagerModules;
        };
      };
      lib = import ./lib { inherit (nixpkgs) lib; };
    };
}
