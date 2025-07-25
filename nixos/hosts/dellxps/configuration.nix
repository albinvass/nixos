# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  overlays,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/15-9520
    inputs.nixos-hardware.nixosModules.dell-xps-15-9520-nvidia
    inputs.home-manager.nixosModules.home-manager
  ];

  system.stateVersion = "23.05";

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      inputs.nixneovimplugins.overlays.default
      inputs.bacon-ls.overlay.${config.nixpkgs.hostPlatform.system}
      inputs.git-toprepo.overlays.default
    ];
  };

  services.flatpak.enable = true;
  nix = {
    package = pkgs.nix;
    settings = {
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "avass"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-substituters = [
        "https://albinvass.cachix.org"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://devenv.cachix.org"
      ];
      extra-trusted-public-keys = [
        "albinvass.cachix.org-1:9BoW/lEIrRQQt7rnktA3qOg9e9G/Fa2SNwqnUEKq8aM="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.avass = {
      imports = [ ./home.nix ];
    };
    extraSpecialArgs = {
      inherit inputs;
    };
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  networking = {
    hostName = "dellxps";
    networkmanager = {
      enable = true;
    };
  };

  time.timeZone = "Europe/Stockholm";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "sv_SE.UTF-8";
      LC_IDENTIFICATION = "sv_SE.UTF-8";
      LC_MEASUREMENT = "sv_SE.UTF-8";
      LC_MONETARY = "sv_SE.UTF-8";
      LC_NAME = "sv_SE.UTF-8";
      LC_NUMERIC = "sv_SE.UTF-8";
      LC_PAPER = "sv_SE.UTF-8";
      LC_TELEPHONE = "sv_SE.UTF-8";
      LC_TIME = "sv_SE.UTF-8";
    };
  };

  services.xserver.xkb = {
    layout = "se";
    variant = "nodeadkeys";
  };

  console.keyMap = "sv-latin1";

  services = {
    envfs.enable = true;
    logind = {
      lidSwitch = "hibernate";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "hibernate";
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
    printing.enable = true;
    libinput.enable = true;
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  users = {
    groups.avass = { };
    users.avass = {
      isNormalUser = true;
      description = "Albin Vass";
      group = "avass";
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "input"
      ];
      shell = pkgs.fish;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      xsettingsd
      xorg.xrdb
      curl
      git
      dig
      gh
      qemu
      kdePackages.xwaylandvideobridge
      kdePackages.discover
      wl-clipboard
      podman
      composefs
    ];
  };

  programs = {
    fish.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      withPython3 = true;
      withRuby = true;
      withNodeJs = true;
      vimAlias = true;
      viAlias = true;
    };
    steam.enable = true;
    kdeconnect.enable = true;
  };

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;

  virtualisation = {
    libvirtd.enable = true;
    containers = {
      enable = true;
      storage = {
        settings = {
          storage.options.overlay = {
            use_composefs = "true";
          };
          storage.options.pull_options = {
            enable_partial_images = "true";
            convert_images = "true";
          };
        };
      };
    };
    podman = {
      enable = true;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
  };
  security.pam.services.login.enableGnomeKeyring = true;
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };
}
