{ config, pkgs, inputs, homeManagerModules, ... }:
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

  sops = {
    secrets = builtins.mapAttrs (
      k: v: (v // { sopsFile = ./secrets.yaml; })
    ) {
      "ATUIN_KEY" = { path = "${config.xdg.dataHome}/atuin/key";};
    };
  };

  home.shellAliases = {
    "nh-switch" =
      if config.submoduleSupport.enable
      then "nh os switch"
      else "nh home switch";
  };

  programs = {
    nix-index-database.comma.enable = true;
    htop.enable = true;
    awscli.enable = true;
    atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = ["--disable-up-arrow"];
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
    bat.enable = true;
    btop.enable = true;
    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = true;
    };
    go.enable = true;
    jq.enable = true;
    taskwarrior.enable = true;
    nnn = {
      enable = true;
      package = pkgs.nnn.override { withNerdIcons = true;};
      bookmarks = {
        g = "~/git";
        n = "~/git/github/albinvass/nixos";
        c = "~/git/github/cinfinity";
        d = "~/git/github/DCE-devops";
        s = "~/git/gitlab/srenity";
      };
    };
  };

  home.sessionVariables = {
    NNN_ARCHIVE = "\\.(7z|a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|rar|rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)$";
    FLAKE = "/home/avass/git/github/albinvass/nixos";
  };


  home.packages = with pkgs; [
    archivemount
    atool
    azure-cli
    bitwarden-cli
    devcontainer
    devpod
    dig
    libarchive
    tree
    docker-compose
    python311
    #poetry
    rustc
    cargo
    yarn
    cloc
    lsof
    cmake
    coreutils
    gnumake
    nim
    yq
    gnupg
    rsync
    vault
    whois
    sops
    killall
    openssl
    rclone
    sshfs
    ssh-to-age
    ssh-to-pgp
    shellcheck
    taskwarrior-tui
    unrar
    tldr
    dust
    duf
    dogdns
    restic
    sad
    fzf
    statix
    jless
    devenv
    watchexec
    fly
    inputs.nh.packages.${pkgs.system}.default
    inputs.nix-alien.packages.${pkgs.system}.nix-alien
  ];
}
