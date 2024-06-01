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
    catppuccin-yazi = {
      url = "github:catppuccin/yazi";
      flake = false;
    };
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
      formatter.x86_64-linux = pkgs.nixfmt-rfc-style;
      nixosConfigurations = self.lib.importHosts ./hosts {
        inherit inputs;
        inherit (self) nixosModules homeManagerModules;
      };
      nixosModules = self.lib.importModules ./nixos/modules;
      homeManagerModules = self.lib.importModules ./home-manager/modules;
      homeConfigurations."avass@5CG0388QDR" = inputs.home-manager.lib.homeManagerConfiguration {
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
      lib = import ./lib { inherit (nixpkgs) lib; };
    };
}
