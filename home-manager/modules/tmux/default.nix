  {config, pkgs, lib, ...}:
  let
    cfg = config.albinvass.tmux;
  in
  {
  options.albinvass.tmux = {
    enable = lib.mkEnableOption "Enable devtools";
    tmux = {
      default_shell = lib.mkOption {
        type = lib.types.str;
        default = "${config.programs.fish.package}/bin/fish";
        description = "Default shell for tmux";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      tmux = {
        enable = true;
        package =
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
          tmux;
        mouse = true;
        keyMode = "vi";
        prefix = "§";
        terminal = "tmux-256color";
        plugins = with pkgs.tmuxPlugins; [
          {
            plugin = catppuccin;
            extraConfig = /* tmux */ ''
              # Configure the catppuccin plugin
              set -g @catppuccin_flavor "mocha"
              set -g @catppuccin_window_status_style "rounded"
            '';
          }
          {
            plugin = fingers;
            extraConfig = /* tmux */ ''
              set -g @fingers-pattern-0 '(([.\w\-~\$@+]+)?(/[.\w\-@+]+)+/?)'
            '';
          }
          fuzzback
          pain-control
          sensible
          yank
          {
            plugin = tmux-floax;
            extraConfig = /* tmux */ ''
              set -g @floax-change-path 'false'
            '';
          }
        ];
        extraConfig = /* tmux */ ''
          set -g status-right-length 200
          set -g status-left-length 100
          set -g status-left ""

          # These need to be set before battery and cpu
          # but after catppuccin. So we set them here in extraConfig
          # and manually add battery and cpu to be loaded instead since it
          # doesn't fit the regular plugins usecase.
          set -g status-right "#{E:@catppuccin_status_application}"
          set -agF status-right "#{E:@catppuccin_status_cpu}"
          set -ag status-right "#{E:@catppuccin_status_session}"
          set -ag status-right "#{E:@catppuccin_status_uptime}"
          set -agF status-right "#{E:@catppuccin_status_battery}"
          run-shell ${pkgs.tmuxPlugins.battery.rtp}
          run-shell ${pkgs.tmuxPlugins.cpu.rtp}

          # These apparently have to after anything else that edit status-right
          # https://haseebmajid.dev/posts/2023-07-10-setting-up-tmux-with-nix-home-manager/#continuum--resurrect-issues
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
          run-shell ${pkgs.tmuxPlugins.resurrect.rtp}
          run-shell ${pkgs.tmuxPlugins.continuum.rtp}
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5'

          set -g default-shell "${cfg.tmux.default_shell}"
        '';
      };
    };
  };
}
