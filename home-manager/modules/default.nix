{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./chats
    ./devtools
    ./fish
    ./general
    ./git
    ./kubernetes
    ./neovim
    ./wezterm
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
