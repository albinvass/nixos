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
    source = ~/.config/hypr/monitors.conf
    exec-once=polkit-agent-helper-1
    exec-once=waybar
    exec-once=swww init
    input {
      kb_layout = se
      kb_variant =
      kb_model =
      kb_options =
      kb_rules =

      follow_mouse = 1

      touchpad {
          natural_scroll = no
      }

      sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

    }

    general {
      border_size = 1
    }

    misc {
      disable_hyprland_logo = true
    }

    decoration {
      rounding = 6
      col.active_border 0xff444444
    }

    dwindle {
      preserve_split = true
    }

    group {
      groupbar {
        font_family = "Ubuntu Nerd Font"
        font_size	 = 20
      }
    }

    $mainMod = SUPER
    bind = $mainMod, Return, exec, konsole
    bind = $mainMod_SHIFT, Q, killactive,
    bind = $mainMod_SHIFT, E, exit,
    bind = $mainMod, D, exec, rofi -show drun
    bind = $mainMod, C, exec, rofi -show window
    bind = $mainMod, F, togglefloating
    bind = $mainMod, S, togglegroup
    bind = $mainMod, U, moveoutofgroup
    bind = $mainMod, P, pseudo, # dwindle
    bind = $mainMod, V, togglesplit, # dwindle


    # Move focus with mainMod + vim keys
    bind = $mainMod, h, movefocus, l
    bind = $mainMod, j, movefocus, d
    bind = $mainMod, k, movefocus, u
    bind = $mainMod, l, movefocus, r
    bind = $mainMod, x, changegroupactive, f
    bind = $mainMod, z, changegroupactive, b

    # Move window with mainMod + vim keys
    bind = $mainMod_SHIFT, h, movewindow, l
    bind = $mainMod_SHIFT, j, movewindow, d
    bind = $mainMod_SHIFT, k, movewindow, u
    bind = $mainMod_SHIFT, l, movewindow, r

    # Switch monitor with mainMod + CTRL + [0-9]
    # TODO: needs a script
    #bind = $mainMod CTRL, 1, focusmonitor, 1
    #bind = $mainMod CTRL, 2, focusmonitor, 2
    #bind = $mainMod CTRL, 3, focusmonitor, 3
    #bind = $mainMod CTRL, 4, focusmonitor, 4
    #bind = $mainMod CTRL, 5, focusmonitor, 5
    #bind = $mainMod CTRL, 6, focusmonitor, 6
    #bind = $mainMod CTRL, 7, focusmonitor, 7
    #bind = $mainMod CTRL, 8, focusmonitor, 8
    #bind = $mainMod CTRL, 9, focusmonitor, 9
    #bind = $mainMod CTRL, 0, focusmonitor, 10

    # Switch workspaces with mainMod + [0-9]
    bind = $mainMod, 1, split-workspace, 1
    bind = $mainMod, 2, split-workspace, 2
    bind = $mainMod, 3, split-workspace, 3
    bind = $mainMod, 4, split-workspace, 4
    bind = $mainMod, 5, split-workspace, 5
    bind = $mainMod, 6, split-workspace, 6
    bind = $mainMod, 7, split-workspace, 7
    bind = $mainMod, 8, split-workspace, 8
    bind = $mainMod, 9, split-workspace, 9
    bind = $mainMod, 0, split-workspace, 10

    # Move active window to a workspace with mainMod + SHIFT + [0-9]
    bind = $mainMod SHIFT, 1, split-movetoworkspace, 1
    bind = $mainMod SHIFT, 2, split-movetoworkspace, 2
    bind = $mainMod SHIFT, 3, split-movetoworkspace, 3
    bind = $mainMod SHIFT, 4, split-movetoworkspace, 4
    bind = $mainMod SHIFT, 5, split-movetoworkspace, 5
    bind = $mainMod SHIFT, 6, split-movetoworkspace, 6
    bind = $mainMod SHIFT, 7, split-movetoworkspace, 7
    bind = $mainMod SHIFT, 8, split-movetoworkspace, 8
    bind = $mainMod SHIFT, 9, split-movetoworkspace, 9
    bind = $mainMod SHIFT, 0, split-movetoworkspace, 10


    # Example special workspace (scratchpad)
    bind = $mainMod, comma, togglespecialworkspace, magic
    bind = $mainMod SHIFT, comma, movetoworkspace, special:magic

    # Scroll through existing workspaces with mainMod + scroll
    bind = $mainMod, mouse_down, workspace, e+1
    bind = $mainMod, mouse_up, workspace, e-1

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = $mainMod, mouse:272, movewindow
    bindm = $mainMod, mouse:273, resizewindow

    # Brightness, Audio etc
    bind=,XF86MonBrightnessDown, exec, brillo -q -U 5
    bind=,XF86MonBrightnessUp, exec, brillo -q -A 5
    bind=,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+
    bind=,XF86AudioLowerVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-
    bind=,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    bind=,XF86AudioPlay, exec, playerctl play-pause

    gestures {
      workspace_swipe = true
      workspace_swipe_distance = 400
      workspace_swipe_min_speed_to_force = 50
      workspace_swipe_cancel_ratio = 0.10
      workspace_swipe_invert = false
    }
    plugin {
      split-monitor-workspaces {
        count = 10
      }

      touch_gestures {
        # The default sensitivity is probably too low on tablet screens,
        # I recommend turning it up to 4.0
        sensitivity = 4.0

        # must be >= 3
        workspace_swipe_fingers = 3

        experimental {
          # send proper cancel events to windows instead of hacky touch_up events,
          # NOT recommended as it crashed a few times, once it's stabilized I'll make it the default
          send_cancel = 0
        }
      }
    }
  '';
}
