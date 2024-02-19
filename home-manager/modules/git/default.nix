{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git-review
  ];
  programs = {
    gh.enable = true;
    gh-dash.enable = true;
    git = {
      enable = true;
      delta = {
        enable = true;
        options = {
          side-by-side = true;
        };
      };
      userEmail = "albinvass@gmail.com";
      userName = "Albin Vass";
      extraConfig = {
        credential.helper = "${pkgs.gitAndTools.gitFull}/bin/git-credential-libsecret";
        merge.conflictStyle = "zdiff3";
        pull.rebase = true;
        push.autoSetupRemote = true;
        rerere.enabled = true;
        branch.sort = "-committerdate";
        tag.sort = "-committerdate";
        fetch.prune = true;
        fetch.prunetags = true;
      };
    };
  };
}
