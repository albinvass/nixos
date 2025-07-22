{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.albinvass.zsh;
in
{
  options.albinvass.zsh = {
    enable = lib.mkEnableOption "Enable zsh configuration";
  };
  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      LS_COLORS = builtins.readFile (
        pkgs.runCommand "vivid-catppuccin-mocha" { } ''
          ${pkgs.vivid}/bin/vivid generate catppuccin-mocha > $out
        ''
      );
    };
    programs = {
      starship = {
        enable = true;
        enableZshIntegration = true;
        settings =
          let
            flavour = "mocha";
          in
          {
            add_newline = true;
            palette = "catppuccin_${flavour}";
          }
          // builtins.fromTOML (builtins.readFile "${inputs.catppuccin-starship}/themes/${flavour}.toml");
      };
      zsh = {
        enable = true;
        initContent = # bash
          ''
            if [ -f "$HOME/.secrets" ]; then
              source "$HOME/.secrets"
            fi

            if [ -f "$HOME/.local-secrets" ]; then
              source "$HOME/.local-secrets"
            fi

            zellij_tab_name_update() {
              if [[ -n $ZELLIJ ]]; then
                local current_dir=$PWD
                if [[ $current_dir == $HOME ]]; then
                    current_dir="~"
                else
                    current_dir=''${current_dir##*/}
                fi
                command nohup zellij action rename-tab $current_dir >/dev/null 2>&1
              fi
            }

            chpwd_functions+=(zellij_tab_name_update)
          '';
        enableCompletion = false;
        autosuggestion.enable = true;
        history.extended = true;
        oh-my-zsh = {
          enable = true;
          plugins = [
            "git"
            "kubectl"
            "ripgrep"
          ];
          theme = "robbyrussell";
        };
      };
    };
  };
}
