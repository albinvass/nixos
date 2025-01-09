{ pkgs, ... }:
{
  home.packages = with pkgs; [ pkgs.nerd-fonts.ubuntu ];
  programs.waybar = {
    enable = true;
    style = builtins.readFile ./style.css;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [ "hyprland/workspaces" ];

        modules-center = [ "hyprland/window" ];

        modules-right = [
          "custom/spotify"
          "cpu"
          "memory"
          "network"
          "pulseaudio"
          "backlight"
          "tray"
          "battery"
          "clock"
        ];

        "hyprland/workspaces" = {
          all-outputs = true;
          disable-scroll = true;
        };

        "custom/spotify" = {
          "format" = " {}";
          "max-length" = 40;
          "interval" = 30;
          "exec" =
            let
              script =
                pkgs.writeScriptBin "mediaplayer.sh" # bash
                  ''
                    #!${pkgs.bash}/bin/bash
                    player_status=$(${pkgs.playerctl}/bin/playerctl status 2> /dev/null)
                    if [ "$player_status" = "Playing" ]; then
                        echo "$(${pkgs.playerctl}/bin/playerctl metadata artist) - $(${pkgs.playerctl}/bin/playerctl metadata title)"
                    elif [ "$player_status" = "Paused" ]; then
                        echo " $(${pkgs.playerctl}/bin/playerctl metadata artist) - $(${pkgs.playerctl}/bin/playerctl metadata title)"
                    fi
                  '';
            in
            "${script}/bin/mediaplayer.sh";
          "exec-if" = "pgrep spotify";
        };

        "tray" = {
          "spacing" = 10;
        };

        "clock" = {
          "tooltip-format" = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
          "format-alt" = "{:%Y-%m-%d}";
        };

        "cpu" = {
          "format" = " {usage}%";
        };

        "memory" = {
          "format" = " {}%";
        };

        "backlight" = {
          "format" = "{icon} {percent}%";
          "format-icons" = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
        };

        "battery" = {
          "states" = {
            "warning" = 30;
            "critical" = 15;
          };
          "format" = "{icon}   {capacity}%";
          "format-charging" = "⚡ {capacity}%";
          "format-plugged" = " {capacity}%";
          "format-alt" = "{icon} {time}";
          "format-icons" = [
            ""
            ""
            ""
            ""
            ""
          ];
        };

        "network" = {
          "format-wifi" = "{essid} ({signalStrength}%) ";
          "format-ethernet" = "{ifname}: {ipaddr}/{cidr} ";
          "format-disconnected" = "Disconnected ⚠";
        };
      };
    };
  };
}
