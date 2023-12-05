{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.swww-images;
in
{
  options = {
    services.swww-images = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to enable sww-images service.
        '';
      };
      refreshInterval = mkOption {
        default = "60m";
        description = ''
          How often to update wallpapers.
        '';
      };
      imageDirectory = mkOption {
        default = ../../wallpapers;
        description = ''
          Directory where images are stored by resolution.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    systemd.user.timers."swww-images" = {
      Unit = {
        Description = "Update wallpaper images.";
      };
      Timer = {
        OnBootSec = "0m";
        OnStartupSec = "5s";
        OnUnitInactiveSec=cfg.refreshInterval;
        Unit = "swww-images.service";
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
    systemd.user.services."swww-images" = {
      Unit = {
        Description = "Update wallpaper images.";
      };
      Service =
      let
        script = pkgs.writeScriptBin "swww-images" /* bash */ ''
          #!${pkgs.bash}/bin/bash

          # Will fail until swww daemon is running
          until ${pkgs.swww}/bin/swww query > /dev/null; do sleep 1; done
          DISPLAYS="$(${pkgs.swww}/bin/swww query)"
          # See https://superuser.com/a/284226
          while IFS= read -r DISPLAY || [[ -n $DISPLAY ]] ; do
            RESOLUTION=$(echo "$DISPLAY" \
                       | "${pkgs.coreutils}/bin/cut" -d ',' -f 1 \
                       | "${pkgs.coreutils}/bin/cut" -d ' ' -f 2)
            OUTPUT=$(echo "$DISPLAY" \
                   | "${pkgs.coreutils}/bin/cut" -d ',' -f 1 \
                   | "${pkgs.coreutils}/bin/cut" -d ' ' -f 1 \
                   | "${pkgs.coreutils}/bin/tr" -d ':')
            if [ -d "${cfg.imageDirectory}/$RESOLUTION" ]; then
              WALLPAPER=$("${pkgs.findutils}/bin/find" "${cfg.imageDirectory}/$RESOLUTION" -mindepth 1 -maxdepth 1 \
                        | "${pkgs.coreutils}/bin/sort" -R \
                        | "${pkgs.coreutils}/bin/tail" -n1)
            else
              WALLPAPER=$("${pkgs.findutils}/bin/find" "${cfg.imageDirectory}" -mindepth 2 -maxdepth 2 \
                        | "${pkgs.coreutils}/bin/sort" -R \
                        | "${pkgs.coreutils}/bin/tail" -n1)
            fi
            "${pkgs.swww}/bin/swww" img "$WALLPAPER" --outputs "$OUTPUT"
          done < <(printf '%s' "$DISPLAYS")
        '';
      in {
        ExecStart = "${script}/bin/swww-images";
      };
    };
  };
}
