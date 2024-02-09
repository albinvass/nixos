{ pkgs, hyprland, hyprgrass, nwg-displays, split-monitor-workspaces, ... }:
{
  imports = [
    ../konsole
    ../waybar
    ../swww-images
    hyprland.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    xwaylandvideobridge
    xdg-desktop-portal
    libsForQt5.polkit-kde-agent
    brillo
    playerctl
    swww
    nwg-displays.packages.${pkgs.system}.default
    wl-clipboard
    rofimoji
  ];

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
  };
  wayland.windowManager.hyprland = {
    enable = true;
    plugins = [
      hyprgrass.packages.${pkgs.system}.default
      split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
    ];

    settings = {
      "$mainMod" = "SUPER";
      "$altMod" = "SUPERALT";

      source = [ "~/.config/hypr/monitors.conf" ];
      exec-once = [
        "waybar"
        "swww init"
        "[workspace 1 silent] konsole"
        "[workspace 2 silent] konsole"
        "[workspace 3 silent; group] microsoft-edge"

        "[workspace 5 silent; group] slack"
        "[workspace 5 silent; group] discord"
        "[workspace 5 silent; group] element-desktop"
        "[workspace 5 silent; group] signal-desktop"
      ];
      input = {
        kb_layout = "se";
        follow_mouse = 1;
        touchpad = {
            natural_scroll = "no";
        };
        sensitivity = 0;
      };
      general = {
        border_size = 1;
      };
      misc = {
        disable_hyprland_logo = true;
      };
      decoration = {
        rounding = 6;
      };
      dwindle = {
        preserve_split = true;
      };
      group = {
        groupbar = {
          font_family = "Ubuntu Nerd Font";
          font_size	 = 20;
        };
      };
      gestures = {
        workspace_swipe = true;
        workspace_swipe_distance = 400;
        workspace_swipe_min_speed_to_force = 50;
        workspace_swipe_cancel_ratio = 0.10;
        workspace_swipe_invert = false;
      };
      plugin = {
        split-monitor-workspaces = {
          count = 10;
        };

        touch_gestures = {
          # The default sensitivity is probably too low on tablet screens,
          # I recommend turning it up to 4.0
          sensitivity = 4.0;

          # must be >= 3
          workspace_swipe_fingers = 3;

          experimental = {
            # send proper cancel events to windows instead of hacky touch_up events,
            # NOT recommended as it crashed a few times, once it's stabilized I'll make it the default
            send_cancel = 0;
          };
        };
      };
      windowrulev2 = [
        "workspace silent 5,class:^Slack$"
        "group,class:^Slack$"
        "workspace silent 5,class:^discord$"
        "group,class:^discord$"
        "workspace silent 5,class:^Element$"
        "group,class:^Element$"
        "workspace silent 5,class:^Signal$"
        "group,class:^Signal$"
      ];
      bind = [
        "$mainMod, Return, exec, konsole"
        "$altMod, 1, exec, wezterm ssh avass@65.108.153.140"
        "$mainMod_SHIFT, Q, killactive,"
        "$mainMod_SHIFT, E, exit,"
        "$mainMod, D, exec, rofi -show drun"
        "$mainMod_SHIFT, D, exec, rofimoji"
        "$mainMod, C, exec, rofi -show window"
        "$mainMod, F, fullscreen, 1"
        "$mainMod, S, togglegroup"
        "$mainMod, U, moveoutofgroup"
        "$mainMod, P, pseudo," # dwindle
        "$mainMod, V, togglesplit," # dwindle

        # Move focus with mainMod + vim keys
        "$mainMod, h, movefocus, l"
        "$mainMod, j, movefocus, d"
        "$mainMod, k, movefocus, u"
        "$mainMod, l, movefocus, r"
        "$mainMod, x, changegroupactive, f"
        "$mainMod, z, changegroupactive, b"

        # Move window with mainMod + vim keys
        "$mainMod_SHIFT, h, movewindow, l"
        "$mainMod_SHIFT, j, movewindow, d"
        "$mainMod_SHIFT, k, movewindow, u"
        "$mainMod_SHIFT, l, movewindow, r"

        # Switch workspaces with mainMod + [0-9]
        "$mainMod, 1, split-workspace, 1"
        "$mainMod, 2, split-workspace, 2"
        "$mainMod, 3, split-workspace, 3"
        "$mainMod, 4, split-workspace, 4"
        "$mainMod, 5, split-workspace, 5"
        "$mainMod, 6, split-workspace, 6"
        "$mainMod, 7, split-workspace, 7"
        "$mainMod, 8, split-workspace, 8"
        "$mainMod, 9, split-workspace, 9"
        "$mainMod, 0, split-workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mainMod SHIFT, 1, split-movetoworkspace, 1"
        "$mainMod SHIFT, 2, split-movetoworkspace, 2"
        "$mainMod SHIFT, 3, split-movetoworkspace, 3"
        "$mainMod SHIFT, 4, split-movetoworkspace, 4"
        "$mainMod SHIFT, 5, split-movetoworkspace, 5"
        "$mainMod SHIFT, 6, split-movetoworkspace, 6"
        "$mainMod SHIFT, 7, split-movetoworkspace, 7"
        "$mainMod SHIFT, 8, split-movetoworkspace, 8"
        "$mainMod SHIFT, 9, split-movetoworkspace, 9"
        "$mainMod SHIFT, 0, split-movetoworkspace, 10"

        # Special workspace
        "$mainMod, comma, togglespecialworkspace, magic"
        "$mainMod SHIFT, comma, movetoworkspace, special:magic"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Brightness, Audio etc
        ", XF86MonBrightnessDown, exec, brillo -q -U 5"
        ", XF86MonBrightnessUp, exec, brillo -q -A 5"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
      ];
      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };

  services.mako = {
    enable = true;
    defaultTimeout = 4000;
  };

  #services.mpd.enable = true;

  services.swww-images = {
    enable = true;
  };

  wayland.windowManager.hyprland.extraConfig = ''
    # will switch to a submap called resize
    bind = $mainMod, R, submap, resize
    submap = resize
    binde = , h, resizeactive, -10 0
    binde = , j, resizeactive, 0 10
    binde = , l, resizeactive, 10 0
    binde = , k, resizeactive, 0 -10
    bind = , escape, submap, reset
    submap = reset
  '';
}
