{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git-review
  ];
  programs = {
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
      };
    };
  };
}
