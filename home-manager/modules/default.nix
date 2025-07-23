{ config, lib, inputs, ... }:
{
  imports = [
    ./chats
    ./devtools
    ./git
    ./kubernetes
    ./neovim
    ./wezterm
    ./zsh
  ];
  options.albinvass = {
    gitDirectory = lib.options.mkOption {
      default = "${config.home.homeDirectory}/git/github/albinvass/nixos";
    };
  };
  config = {
    nixpkgs.overlays = [
      inputs.nixgl.overlay
    ];
  };
}
