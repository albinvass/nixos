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
  outputs = { self, nixpkgs, ... }@inputs:

  rec {
    nixosConfigurations = 
      let
        hosts = self.lib.getDirectories ./hosts;
        mkNixosConfigurations = (host: {
          "${host}" = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./hosts/${host}/configuration.nix ];
            specialArgs = { inherit inputs nixosModules homeManagerModules;};
          };
        });
      in nixpkgs.lib.attrsets.mergeAttrsList (builtins.map mkNixosConfigurations hosts);
    nixosModules = {
      devtools = {
        imports = [
          inputs.home-manager.nixosModules.home-manager
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
          ./hosts/dellxps/home.nix
          homeManagerModules.hyprland
          homeManagerModules.devtools
          homeManagerModules.social-media
          homeManagerModules.music
        ];
      };
      "avass@wsl" = {
        imports = [
          ./hosts/dellxps/home.nix
          homeManagerModules.devtools
        ];
      };
    } // self.lib.importModules ./home-manager/modules;
    lib =
    let
      lib = nixpkgs.lib;
    in rec {
      filterDirectories = (files: lib.attrsets.filterAttrs (name: type: type == "directory") files);
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
