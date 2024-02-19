{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOs/nixos-hardware/master";
    nixneovimplugins.url = "github:NixNeovim/NixNeovim";

    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
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
      url = "github:nwg-piotr/nwg-displays?ref=v0.3.10";
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
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-hardware, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
  in rec {
    nixosConfigurations = {
      "dellxps" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/laptop/configuration.nix
          nixosModules.hyprland
          nixosModules.gaming
          nixosModules.docker
          nixosModules.tailscale
          # https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/15-9520
          nixos-hardware.nixosModules.dell-xps-15-9520-nvidia
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [ inputs.nixneovimplugins.overlays.default ];
          }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.avass = homeManagerModules."avass@dellxps";
            home-manager.extraSpecialArgs = with inputs; {
              inherit inputs homeManagerModules;
            };
          }
        ];
      };
      "wsl" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/wsl/configuration.nix
          inputs.wsl.nixosModules.wsl
          nixosModules.docker
          nixosModules.tailscale
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.avass = homeManagerModules."avass@wsl";
            home-manager.extraSpecialArgs = {
              inherit inputs homeManagerModules;
            };
          }
        ];
      };
    };
    nixOnDroidConfigurations = {
      "avass@s22ultra" = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        modules = [
          {
            # Read Nix-on-Droid changelog before changing this value
            system.stateVersion = "23.05";

            nix.extraOptions = ''
              experimental-features = nix-command flakes
            '';

            home-manager.extraSpecialArgs = {
              inherit inputs homeManagerModules;
            };
            home-manager.config = { pkgs, inputs, homeManagerModules, ... }:
              {
                home.stateVersion = "23.05";
                imports = [
                  homeManagerModules.devtools
                ];
              };
            }
        ];
      };
    };
    nixosModules = {
      devtools = {
        imports = [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.avass = homeManagerModules."avass@headless";
            home-manager.extraSpecialArgs = {
              inherit inputs homeManagerModules;
            };
          }
        ];
      };
    } // self.lib.importModules ./nixos/modules;
    homeManagerModules = {
      "avass@headless" = {
        xdg.userDirs.enable = true;

        home.username = "avass";
        home.homeDirectory = "/home/avass";
        home.stateVersion = "23.11";

        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;
        imports = [
          homeManagerModules.devtools
        ];
      };
      "avass@dellxps" = {
        imports = [
          ./hosts/laptop/home.nix
          homeManagerModules.hyprland
          homeManagerModules.devtools
          homeManagerModules.social-media
          homeManagerModules.music
        ];
      };
      "avass@wsl" = {
        imports = [
          ./hosts/laptop/home.nix
          homeManagerModules.devtools
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
