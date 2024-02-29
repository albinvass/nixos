# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, nixosModules, homeManagerModules, inputs, ... }:

{
  system.stateVersion = "23.05"; # Did you read the comment?
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      extra-substituters = [
        "https://albinvass.cachix.org"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
      ];
      extra-trusted-public-keys = [
        "albinvass.cachix.org-1:9BoW/lEIrRQQt7rnktA3qOg9e9G/Fa2SNwqnUEKq8aM="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];
    };
  };
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/15-9520
      inputs.nixos-hardware.nixosModules.dell-xps-15-9520-nvidia
      nixosModules.hyprland
      nixosModules.gaming
      nixosModules.docker
      nixosModules.tailscale
      inputs.home-manager.nixosModules.home-manager
      {
        nixpkgs.overlays = [ inputs.nixneovimplugins.overlays.default ];
      }
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.avass = { imports = [ ./home.nix ]; };
        home-manager.extraSpecialArgs = {
          inherit inputs homeManagerModules;
        };
      }
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.networkmanager.enable = true;
  networking.hostName = "dellxps"; # Define your hostname.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  time.timeZone = "Europe/Stockholm";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
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

  # Configure console keymap
  console.keyMap = "sv-latin1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Add compatibility for /bin/bash etc.
  services.envfs.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  programs.zsh.enable = true;
  users.groups.avass = {};
  users.users.avass = {
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


  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    curl
    git
    dig
    gh
    qemu
  ];

  environment.sessionVariables = {
    XCURSOR_SIZE = "24";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    withRuby = true;
    withNodeJs = true;
    vimAlias = true;
    viAlias = true;
  };

  programs.ssh = {
    enableAskPassword = false;
  };

  virtualisation.libvirtd.enable = true;

  services.logind = {
    lidSwitch = "hibernate";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "hibernate";
  };
}
