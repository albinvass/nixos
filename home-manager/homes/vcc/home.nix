{
  pkgs,
  inputs,
  ...
}:
{
  home = {
    username = "avass";
    homeDirectory = "/home/avass";
    sessionPath = [ "$HOME/.local/bin" ];
    stateVersion = "23.11";
    packages = with pkgs; [
      inputs.nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel
      xclip
      vivaldi
      git-lfs
    ];
  };

  targets.genericLinux.nixGL = {
    inherit (inputs.nixgl) packages;
    defaultWrapper = "mesa";
  };

  albinvass = {
    chats.enable = true;
    devtools.enable = true;
    wezterm = {
      enable = true;
      font_size = 10;
    };
  };
}
