{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./home-manager/modules
  ];

  home.username = "albinvass";
  home.homeDirectory = "/Users/albinvass";
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  albinvass = {
    wezterm = {
      enable = true;
      enable_wayland = false;
      default_prog =
        let
          tmuxWrapper = pkgs.writeShellScript "tmux-wrapper" ''
            export PATH="${config.home.profileDirectory}/bin:$PATH"
            export SHELL="${config.programs.fish.package}/bin/fish"
            exec ${config.programs.tmux.package}/bin/tmux "$@"
          '';
        in
        "${tmuxWrapper}";
    };
    devtools.enable = true;
  };
}
