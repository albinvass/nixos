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
    go
    yarn
    cloc
    lsof
    cmake
    llvmPackages.clangUseLLVM
    coreutils
    gnumake
    nim
    yq
    jq
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
  ];
}
