{
  inputs = {
    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };
    catppuccin-starship = {
      url = "github:catppuccin/starship";
      flake = false;
    };
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    git-toprepo.url = "github:meroton/git-toprepo";
    neorg-overlay.url = "github:nvim-neorg/nixpkgs-neorg-overlay";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOs/nixos-hardware/master";
    nixneovimplugins.url = "github:NixNeovim/NixNeovim";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nixgl.url = "github:guibou/nixGL";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
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
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    openconnect-sso = {
      url = "github:ThinkChaos/openconnect-sso/fix/nix-flake";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wsl = {
      url = "github:nix-community/NixOS-WSL";
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
      pkgs = import nixpkgs { system = "x86_64-linux"; };
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
      formatter.x86_64-linux = pkgs.nixfmt-rfc-style;
      nixosConfigurations = self.lib.importHosts ./hosts {
        inherit inputs;
        inherit (self) nixosModules homeManagerModules overlays;
      };
      nixosModules = self.lib.importModules ./nixos/modules;
      overlays.openconnect = (self: super: {
        # See: https://gitlab.com/openconnect/openconnect/-/issues/730
        openconnect = super.openconnect.overrideAttrs (old: {
          src = pkgs.fetchFromGitLab {
            owner = "openconnect";
            repo = "openconnect";
            rev = "32971c1b1e1506e2e9fdb215b8ba6f3b930fe98d";
            hash = "sha256-NtIFZ4iARPgn5qySdybqNMS8rVtAbuBKViiC9BXZvno=";
          };
        });
      });
      homeManagerModules = self.lib.importModules ./home-manager/modules;
      homeConfigurations."avass@5CG4420JDB" = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [
            inputs.nixneovimplugins.overlays.default
            inputs.nixgl.overlay
            inputs.neorg-overlay.overlays.default
          ];
        };
        modules = [
          ./homes/vcc/home.nix
          homeManagerModules.devtools
          homeManagerModules.social-media
          homeManagerModules.music
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
