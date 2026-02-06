{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.albinvass.tmux;
in
{
  options.albinvass.tmux = {
    enable = lib.mkEnableOption "Enable devtools";
  };
  config = lib.mkIf cfg.enable {
    home.file."${config.xdg.configHome}/tmux/".source =
      config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/home-manager/modules/tmux/tmux";
    home.file."${config.xdg.configHome}/albinvass/tmux/" = {
      source = pkgs.symlinkJoin {
        name = "tmux-plugins";
        paths = with pkgs.tmuxPlugins; [
          catppuccin
          fingers
          fuzzback
          pain-control
          sensible
          yank
          tmux-floax
          battery
          cpu
          resurrect
          continuum
          pkgs.fish
        ];
      };
    };
    home.packages =
      let
        # Fixes an issue with the TERM variable being unset causing plugins
        # to fail to render color
        # https://github.com/tmux/tmux/commit/55d660a548cbeb8cb3b6975cc67fa1b0b031a4e8
        tmux = pkgs.tmux.overrideAttrs (old: {
          version = "git";
          src = pkgs.fetchFromGitHub {
            owner = "tmux";
            repo = "tmux";
            rev = "95b4bb51c640664ac4602dd24d29bb7c112c83c5";
            sha256 = "sha256-j9yvisNsaJuvoWZ72HTbnCjXgU12RSz2tfG3Q2E/pjA";
          };
        });
      in
      [ tmux ];
  };
}
