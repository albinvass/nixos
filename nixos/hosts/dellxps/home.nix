{
  pkgs,
  ...
}:
{
  imports = [
    ./desktop-files
    ../../../home-manager/modules
  ];

  fonts.fontconfig.enable = true;

  xdg.userDirs.enable = true;

  home.username = "avass";
  home.homeDirectory = "/home/avass";
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    calibre
    discord
    bitwarden
    libreoffice-qt
    lutris
    protonup-qt
    hunspell
    hunspellDicts.sv_SE
    hunspellDicts.en_US
    # See: https://discourse.nixos.org/t/new-install-vivaldi-not-starting/53282/8
    (vivaldi.overrideAttrs (oldAttrs: {
      dontWrapQtApps = false;
      dontPatchELF = true;
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
        pkgs.kdePackages.wrapQtAppsHook
      ];
    }))
    firefox
    synergy
    waynergy
    obs-studio
    onlyoffice-bin
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  albinvass = {
    wezterm = {
      enable = true;
      enable_wayland = true;
    };
    devtools.enable = true;
    chats.enable = true;
  };
}
