{
  config,
  pkgs,
  inputs,
  homeManagerModules,
  ...
}:
{
  imports = [
    homeManagerModules.neovim
    homeManagerModules.zsh
    homeManagerModules.git
    homeManagerModules.github
    homeManagerModules.kubernetes
    homeManagerModules.sops
    inputs.sops-nix.homeManagerModules.sops
    inputs.nix-index-database.hmModules.nix-index
  ];

  home.file = {
    tools = {
      source = ../../../tools;
      recursive = true;
      # Broken in nix 2.18.2
      # source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/git/github/albinvass/nixos/tools";
    };
  };

  sops = {
    secrets = builtins.mapAttrs (k: v: (v // { sopsFile = ./secrets.yaml; })) {
      "ATUIN_KEY" = {
        path = "${config.xdg.dataHome}/atuin/key";
      };
    };
  };

  home.shellAliases = {
    "nh-switch" = if config.submoduleSupport.enable then "nh os switch" else "nh home switch";
    "cd" = "z";
  };

  programs = {
    nix-index-database.comma.enable = true;
    htop.enable = true;
    awscli.enable = true;
    atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        dotfiles.enabled = true;
      };
    };
    ripgrep.enable = true;
    k9s.enable = true;
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    bat = {
      enable = true;
      config = {
        theme = "Catppuccin Mocha";
      };
      themes = {
        "Catppuccin Mocha" = {
          src = inputs.catppuccin-bat;
          file = "themes/Catppuccin Mocha.tmTheme";
        };
      };
    };
    btop.enable = true;
    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = true;
    };
    go.enable = true;
    jq.enable = true;
    yazi = {
      enable = true;
      enableZshIntegration = true;
      theme = builtins.fromTOML (builtins.readFile "${inputs.catppuccin-yazi}/themes/mocha/catppuccin-mocha-blue.toml")
        // {
          manager = {
            syntect_theme = "${inputs.catppuccin-bat}/themes/Catppuccin Mocha.tmTheme";
          };
        };
    };
    zellij = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        theme = "catppuccin-mocha";
        default_shell = "zsh";
        default_mode = "locked";
      };
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home.sessionVariables = {
    FLAKE = "${config.home.homeDirectory}/git/github/albinvass/nixos";
    ZELLIJ_AUTO_EXIT = "true";
  };

  home.packages = with pkgs; [
    archivemount
    attic-client
    atool
    azure-cli
    dig
    libarchive
    tree
    docker-compose
    python311
    virtualenv
    rustc
    cargo
    yarn
    cloc
    lsof
    cmake
    gnumake
    yq
    gnupg
    rsync
    vault
    whois
    sops
    killall
    openssl
    ssh-to-age
    ssh-to-pgp
    shellcheck
    unrar
    tldr
    dust
    duf
    parted
    cloud-utils
    dogdns
    restic
    drawio
    fzf
    statix
    jless
    devenv
    watchexec
    python3Packages.nox
    pyright
    inputs.nh.packages.${pkgs.system}.default
    inputs.nix-alien.packages.${pkgs.system}.nix-alien
  ];
}
