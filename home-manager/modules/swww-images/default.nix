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
            echo "$DISPLAY"
            "${pkgs.swww}/bin/swww" img ${cfg.imageDirectory}/2160x1440/samurai-in-the-mountains.jpg
          done < <(printf '%s' "$DISPLAYS")
        '';
      in {
        ExecStart = "${script}/bin/swww-images";
      };
    };
  };
}
