{
  pkgs,
  inputs,
  ...
}:
{
  home = {
    username = "albin-vass";
    homeDirectory = "/home/albin-vass";
    sessionPath = [ "$HOME/.local/bin" ];
    stateVersion = "25.11";
    packages = with pkgs; [
      nixgl.nixGLIntel
      xclip
      brightnessctl
      nodejs
      gemini-cli-bin
      podman
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
