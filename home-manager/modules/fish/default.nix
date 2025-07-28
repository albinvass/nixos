{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.albinvass.fish;
in
{
  options.albinvass.fish = {
    enable = lib.mkEnableOption "Enable fish configuration";
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
        enableFishIntegration = true;
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
      fish = {
        enable = true;
        shellAbbrs = {
          gau = "git add --update";
          gd = "git diff";
          "gcn!" = "git commit -v --no-edit --amend";
          glol = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'";
          gpr = "git pull --rebase";
          gpristine = "git reset --hard && git clean -dffx";
          gpsup = "git push --set-upstream origin $(git branch --show-current)";
          gst = "git status";
        };
        shellInit = /* fish */ ''
          set -g fish_key_bindings fish_vi_key_bindings
        '';
      };
    };
  };
}

