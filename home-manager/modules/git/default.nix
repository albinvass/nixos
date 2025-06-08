{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git-review
    git-toprepo
  ];
  programs = {
    gh.enable = true;
    gh-dash.enable = true;
    git = {
      enable = true;
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
}
