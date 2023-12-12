{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git-review
  ];
  programs = {
    git = {
      enable = true;
      userEmail = "albinvass@gmail.com";
      userName = "Albin Vass";
      extraConfig = {
        credential.helper = "${pkgs.gitAndTools.gitFull}/bin/git-credential-libsecret";
      };
    };
  };
}
