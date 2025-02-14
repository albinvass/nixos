{ pkgs, homeManagerModules, inputs, ... }:
{
  imports = [
    ./desktop-files
    homeManagerModules.thunderbird
    homeManagerModules.devtools
    homeManagerModules.social-media
    homeManagerModules.music
  ];

  fonts.fontconfig.enable = true;

  xdg.userDirs.enable = true;

  home.username = "avass";
  home.homeDirectory = "/home/avass";
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    discord
    bitwarden
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
    inputs.git-toprepo.packages.${pkgs.system}.git-toprepo
  ];

  programs = {
    joplin-desktop = {
      enable = true;
    };
  };

  home.sessionVariables = { };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
