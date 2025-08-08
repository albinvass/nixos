{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.albinvass.devtools;
in
{
  imports = [
    inputs.nix-index-database.homeModules.nix-index
  ];
  options.albinvass.devtools = {
    enable = lib.mkEnableOption "Enable devtools";
  };
  config = lib.mkIf cfg.enable {
    albinvass.fish.enable = true;
    albinvass.git.enable = true;
    albinvass.kubernetes.enable = true;
    albinvass.neovim.enable = true;

    nixpkgs.overlays = [
      inputs.nh.overlays.default
    ];

    home.file = {
      tools = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/tools";
      };
      ".bazelrc" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/home-manager/modules/devtools/bazel/.bazelrc";
      };
      "${config.xdg.configHome}/btop/themes" = {
        source = "${inputs.catppuccin-btop}/themes";
        recursive = true;
      };
    };

    home.shellAliases = {
      "nh-switch" = if config.submoduleSupport.enable then "nh os switch" else "nh home switch";
      "cd" = "z";
    };

    programs = {
      bacon = {
        enable = true;
        settings = {
          jobs.bacon-ls = {
            command = [
              "cargo"
              "clippy"
              "--workspace"
              "--tests"
              "--all-targets"
              "--all-features"
              "--message-format"
              "json-diagnostic-rendered-ansi"
            ];
            analyzer = "cargo_json";
            need_stdout = true;
          };

          exports.cargo-json-spans = {
            auto = true;
            exporter = "analyzer";
            line_format = "{diagnostic.level}|:|{span.file_name}|:|{span.line_start}|:|{span.line_end}|:|{span.column_start}|:|{span.column_end}|:|{diagnostic.message}|:|{diagnostic.rendered}|:|{span.suggested_replacement}";
            path = ".bacon-locations";
          };
        };
      };
      nix-index-database.comma.enable = true;
      awscli.enable = true;
      fzf = {
        enable = true;
        enableFishIntegration = config.albinvass.fish.enable;
      };
      ripgrep.enable = true;
      k9s.enable = true;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      bat = {
        enable = true;
        config = {
          theme = "Catppuccin Mocha";
        };
        themes = {
          "Catppuccin Mocha" = {
            src = inputs.catppuccin-bat;
            file = "themes/Catppuccin Mocha.tmTheme";
          };
        };
      };
      btop = {
        enable = true;
        settings = {
          color_theme = "catppuccin_mocha";
          theme_background = false;
        };
      };
      eza = {
        enable = true;
        enableFishIntegration = config.albinvass.fish.enable;
        git = true;
        icons = "auto";
      };
      go.enable = true;
      jq.enable = true;
      ssh = {
        enable = true;
        includes = [ "~/.ssh/local_config" ];
        extraConfig = ''
          IdentityFile=~/.ssh/id_ed25519_sk_red
          IdentityFile=~/.ssh/id_ed25519_sk_green
        '';
      };
      yazi = {
        enable = true;
        enableFishIntegration = config.albinvass.fish.enable;
        theme =
          builtins.fromTOML (
            builtins.readFile "${inputs.catppuccin-yazi}/themes/mocha/catppuccin-mocha-blue.toml"
          )
          // {
            manager = {
              syntect_theme = "${inputs.catppuccin-bat}/themes/mocha/catppuccin-mocha-blue.toml";
            };
          };
      };
      tmux = {
        enable = true;
        mouse = true;
        keyMode = "vi";
        prefix = "§";
        terminal = "tmux-256color";
        plugins = with pkgs.tmuxPlugins; [
          {
            plugin = catppuccin;
            extraConfig = /* tmux */ ''
                # Configure the catppuccin plugin
                set -g @catppuccin_flavor "mocha"
                set -g @catppuccin_window_status_style "rounded"
              '';
          }
          fingers
          fuzzback
          pain-control
          sensible
          yank
          tmux-floax
        ];
        extraConfig = /* tmux */ ''
            set -g status-right-length 200
            set -g status-left-length 100
            set -g status-left ""

            # These need to be set before battery and cpu
            # but after catppuccin. So we set them here in extraConfig
            # and manually add battery and cpu to be loaded instead since it
            # doesn't fit the regular plugins usecase.
            set -g status-right "#{E:@catppuccin_status_application}"
            set -agF status-right "#{E:@catppuccin_status_cpu}"
            set -ag status-right "#{E:@catppuccin_status_session}"
            set -ag status-right "#{E:@catppuccin_status_uptime}"
            set -agF status-right "#{E:@catppuccin_status_battery}"
            run-shell ${pkgs.tmuxPlugins.battery.rtp}
            run-shell ${pkgs.tmuxPlugins.cpu.rtp}

            # These apparently have to after anything else that edit status-right
            # https://haseebmajid.dev/posts/2023-07-10-setting-up-tmux-with-nix-home-manager/#continuum--resurrect-issues
            set -g @resurrect-strategy-vim 'session'
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
            run-shell ${pkgs.tmuxPlugins.resurrect.rtp}
            run-shell ${pkgs.tmuxPlugins.continuum.rtp}
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '5'
        '';
      };
      zoxide = {
        enable = true;
        enableFishIntegration = config.albinvass.fish.enable;
      };
    };

    home.sessionVariables = {
      NH_FLAKE = pkgs.lib.mkDefault config.albinvass.gitDirectory;
    };

    home.packages =
      with pkgs;
      let
        bazelIsBazelisk =
          writeShellScriptBin "bazel" # bash
            ''
              #!${pkgs.bash}/bin/bash
              ${pkgs.bazelisk}/bin/bazelisk "$@"
            '';
        s =
          writeShellScriptBin "s" # bash
            ''
              #!${pkgs.bash}/bin/bash
              sudo --preserve-env --preserve-env=PATH env $@
            '';
      in
      with pkgs;
      [
        acpi
        archivemount
        atool
        bazelIsBazelisk
        buildozer
        cloud-utils
        cmake
        devenv
        dig
        docker-compose
        duf
        dust
        fzf
        gcc
        gnumake
        gnupg
        jless
        killall
        libarchive
        lsof
        nh
        openssl
        parted
        python311
        restic
        rsync
        rustup
        s
        shellcheck
        sops
        ssh-to-age
        ssh-to-pgp
        statix
        tldr
        tokei
        unrar
        virtualenv
        watchexec
        whois
        yq
      ];
  };
}
