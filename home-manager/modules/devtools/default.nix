{ pkgs, inputs, homeManagerModules, ... }:
{
  imports = [
    homeManagerModules.neovim
    homeManagerModules.zsh
    homeManagerModules.git
    homeManagerModules.github
    homeManagerModules.kubernetes
    homeManagerModules.sops
    homeManagerModules.srenity
    inputs.sops-nix.homeManagerModules.sops
  ];

  programs = {
    htop.enable = true;
    awscli.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
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
      enableAliases = true;
      git = true;
      icons = true;
    };
    go.enable = true;
    jq.enable = true;
    nnn = {
      enable = true;
      package = (pkgs.nnn.override { withNerdIcons = true;});
      bookmarks = {
        g = "~/git";
      };
    };
  };


  home.packages = with pkgs; [
    azure-cli
    bitwarden-cli
    dig
    tree
    docker-compose
    python311
    poetry
    rustc
    cargo
    yarn
    cloc
    lsof
    cmake
    llvmPackages.clangUseLLVM
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
    ssh-to-age
    ssh-to-pgp
    shellcheck
    tldr
    dust
    duf
    dogdns
  ];
}
