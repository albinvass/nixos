{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.albinvass.git; pygerrit2 =
    with pkgs;
    python3Packages.buildPythonPackage {
      name = "pygerrit2";
      src = inputs.pygerrit2;
      pyproject = true;
      build-system = with python3Packages; [ setuptools ];
      buildInputs = with python3Packages; [
        pbr
        requests
      ];
      PBR_VERSION = "1.0.0";
    };
  gerrit-cli =
    with pkgs;
    python3Packages.buildPythonApplication {
      name = "gerrit-cli";
      src = inputs.gerrit-cli;
      pyproject = false;
      propagatedBuildInputs = with python3Packages; [
        pygerrit2
        requests
      ];
      installPhase = ''
        mkdir -p $out/bin
        install -Dm755 $src/py/gerrit.py $out/bin/gerrit
        install -Dm755 $src/bin/review $out/bin/review
        install -Dm755 $src/bin/fzf-passthrough $out/bin/fzf-passthrough
      '';
    };
in
{
  options.albinvass.git = {
    enable = lib.mkEnableOption "Enable git configuration";
  };
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.git-toprepo.overlays.default
    ];
    home.packages = with pkgs; [
      git-review
      git-toprepo-stamped
      gerrit-cli
    ];
    programs = {
      gh.enable = true;
      gh-dash.enable = true;
      git = {
        enable = true;
        aliases = {
          dl = "-c diff.external=difft log --ext-diff";
          ds = "-c diff.external=difft show --ext-diff";
          dft = "-c diff.external=difft diff --ext-diff";
        };
        difftastic = {
          enable = true;
        };
        userEmail = "git@mail.albinvass.com";
        userName = "Albin Vass";
        extraConfig = {
          credential.helper = "${pkgs.gitAndTools.gitFull}/bin/git-credential-libsecret";
          merge.conflictStyle = "zdiff3";
          fetch.writeCommitGraph = true;
          pull.rebase = true;
          push.autoSetupRemote = true;
          rerere.enabled = true;
          branch.sort = "-committerdate";
          tag.sort = "-committerdate";
          column.ui = "auto";
          fetch.prune = true;
          fetch.prunetags = true;
        };
      };
      mergiraf.enable = true;
    };
  };
}
