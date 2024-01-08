{ pkgs, ... }:
{
  imports = [
    ./desktop-files
  ];

  fonts.fontconfig.enable = true;

  xdg.userDirs.enable = true;

  home.username = "avass";
  home.homeDirectory = "/home/avass";
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    azure-cli
    dig
    tree
    docker-compose
    python311
    poetry
    rustc
    cargo
    go
    yarn
    bitwarden
    bitwarden-cli
    discord
    microsoft-edge
    cloc
    lsof
    cmake
    llvmPackages.clangUseLLVM
    coreutils
    gnumake
    nim
    yq
    jq
    libsForQt5.kwalletmanager
    gnome.seahorse
    dvc-with-remotes
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

  home.sessionVariables = {};

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
