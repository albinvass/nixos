# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  pkgs,
  nixosModules,
  homeManagerModules,
  overlays,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    nixosModules.hyprland
    nixosModules.gaming
    nixosModules.docker
    nixosModules.tailscale
    nixosModules.nh
    # https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/15-9520
    inputs.nixos-hardware.nixosModules.dell-xps-15-9520-nvidia
    inputs.home-manager.nixosModules.home-manager
  ];

  system.stateVersion = "23.05";

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      inputs.nixneovimplugins.overlays.default
      inputs.neorg-overlay.overlays.default
      inputs.openconnect-sso.overlays.default
      overlays.openconnect
    ];
  };

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
      inherit inputs homeManagerModules;
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
      plugins = with pkgs; [networkmanager-openconnect];
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

  # Configure console keymap
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
    xserver.libinput.enable = true;
  };

  hardware.pulseaudio.enable = false;
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
        "docker"
        "libvirtd"
      ];
      shell = pkgs.zsh;
    };
  };

  environment = {
    sessionVariables = {
      XCURSOR_SIZE = "24";
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
    systemPackages = with pkgs; [
      curl
      git
      dig
      gh
      qemu
      openconnect-sso
      xwaylandvideobridge
    ];
  };

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      withPython3 = true;
      withRuby = true;
      withNodeJs = true;
      vimAlias = true;
      viAlias = true;
    };
    ssh = {
      enableAskPassword = false;
    };
    zsh.enable = true;
  };

  services.xserver.desktopManager.plasma6.enable = true;

  virtualisation.libvirtd.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = with pkgs; [
      xdg-desktop-portal
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
      xdg-desktop-portal-kde
    ];
  };
  security.pam.services.login.enableGnomeKeyring = true;
}
