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
      nixgl.nixGLIntel
      xclip
      vivaldi
      git-lfs
    ];
  };

  targets.genericLinux.nixGL = {
    packages = inputs.nixgl.packages;
    defaultWrapper = "mesa";
  };

  albinvass = {
    chats.enable = true;
    devtools.enable = true;
    wezterm.enable = true;
  };
}
