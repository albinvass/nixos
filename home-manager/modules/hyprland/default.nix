{ pkgs, hyprland, hyprgrass, ... }:
{
  imports = [
    ../konsole
    hyprland.homeManagerModules.default
  ];

  programs.fuzzel.enable = true;
  wayland.windowManager.hyprland = {
    enable = true; 
    plugins = [
      hyprgrass.packages.${pkgs.system}.default
    ];
  };

  services.mako = {
    enable = true;
    defaultTimeout = 4000;
  };

  programs.waybar = {
    enable = true;
    settings = {
    };
  };

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once=polkit-agent-helper-1
    exec-once=waybar
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

    decoration {
      rounding = 6
      col.active_border 0xff444444
    }

    $mainMod = SUPER
    bind = $mainMod, Return, exec, konsole
    bind = $mainMod_SHIFT, Q, killactive,
    bind = $mainMod_SHIFT, E, exit,
    bind = $mainMod, D, exec, fuzzel
    bind = $mainMod, F, fullscreen,
    bind = $mainMod, S, exec, togglegroup
    bind = $mainMod, P, pseudo, # dwindle
    bind = $mainMod, V, togglesplit, # dwindle

    # Move focus with mainMod + vim keys
    bind = $mainMod, h, movefocus, l
    bind = $mainMod, j, movefocus, d
    bind = $mainMod, k, movefocus, u
    bind = $mainMod, l, movefocus, r

    # Move window with mainMod + vim keys
    bind = $mainMod_SHIFT, h, movewindow, l
    bind = $mainMod_SHIFT, j, movewindow, d
    bind = $mainMod_SHIFT, k, movewindow, u
    bind = $mainMod_SHIFT, l, movewindow, r

    # Switch workspaces with mainMod + [0-9]
    bind = $mainMod, 1, workspace, 1
    bind = $mainMod, 2, workspace, 2
    bind = $mainMod, 3, workspace, 3
    bind = $mainMod, 4, workspace, 4
    bind = $mainMod, 5, workspace, 5
    bind = $mainMod, 6, workspace, 6
    bind = $mainMod, 7, workspace, 7
    bind = $mainMod, 8, workspace, 8
    bind = $mainMod, 9, workspace, 9
    bind = $mainMod, 0, workspace, 10

    # Move active window to a workspace with mainMod + SHIFT + [0-9]
    bind = $mainMod SHIFT, 1, movetoworkspace, 1
    bind = $mainMod SHIFT, 2, movetoworkspace, 2
    bind = $mainMod SHIFT, 3, movetoworkspace, 3
    bind = $mainMod SHIFT, 4, movetoworkspace, 4
    bind = $mainMod SHIFT, 5, movetoworkspace, 5
    bind = $mainMod SHIFT, 6, movetoworkspace, 6
    bind = $mainMod SHIFT, 7, movetoworkspace, 7
    bind = $mainMod SHIFT, 8, movetoworkspace, 8
    bind = $mainMod SHIFT, 9, movetoworkspace, 9
    bind = $mainMod SHIFT, 0, movetoworkspace, 10

    # Example special workspace (scratchpad)
    bind = $mainMod, comma, togglespecialworkspace, magic
    bind = $mainMod SHIFT, comma, movetoworkspace, special:magic

    # Scroll through existing workspaces with mainMod + scroll
    bind = $mainMod, mouse_down, workspace, e+1
    bind = $mainMod, mouse_up, workspace, e-1

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = $mainMod, mouse:272, movewindow
    bindm = $mainMod, mouse:273, resizewindow

    gestures {
      workspace_swipe = true
      workspace_swipe_distance = 400
      workspace_swipe_min_speed_to_force = 50
      workspace_swipe_cancel_ratio = 0.10
      workspace_swipe_invert = false
    }
    plugin {
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