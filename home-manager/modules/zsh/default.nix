{
  config,
  inputs,
  pkgs,
  ...
}:
{
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
        // builtins.fromTOML (builtins.readFile "${inputs.catppuccin-starship}/palettes/${flavour}.toml");
    };
    zsh = {
      enable = true;
      initExtra = # bash
        ''
          bw-unlock() {
            export BW_SESSION=$(bw unlock --raw)
          }

          bw-login() {
            export BW_SESSION=$(bw login --raw)
          }

          if [ -f "$HOME/.secrets" ]; then
            source "$HOME/.secrets"
          fi

          if [ -f "$HOME/.local-secrets" ]; then
            source "$HOME/.local-secrets"
          fi
        '';
      enableCompletion = false;
      enableAutosuggestions = true;
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

  home.file = {
    ".secrets".text = # bash
      ''

        function list-secrets() {
          subpath=$1
          find "${config.xdg.configHome}/sops-nix/secrets/$subpath" \
            -mindepth 1 -maxdepth 1
        }

        function source-secrets() {
          subpath=$1
          if [[ -v __CLEANUP_SECRETS__ ]]; then
            cleanup-secrets
          fi
          __SECRETS__=("''${(@f)$(list-secrets $subpath)}")

          __CLEANUP_SECRETS__=""
          for secret in "''${__SECRETS__[@]}"; do
            secretname="$(basename $secret)"
            export $secretname="$(cat $secret)"
            __CLEANUP_SECRETS__+="$secretname:"
          done
          export __CLEANUP_SECRETS__
        }

        function cleanup-secrets() {
          for key in ''${(s/:/)__CLEANUP_SECRETS__}; do
            unset $key
          done
          unset __CLEANUP_SECRETS__
        }
      '';
  };
}
