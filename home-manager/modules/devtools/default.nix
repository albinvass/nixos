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
    albinvass.neovim.enable = true;
    albinvass.zsh.enable = true;
    albinvass.git.enable = true;
    albinvass.kubernetes.enable = true;

    home.file = {
      tools = {
        #source = ../../../tools;
        #recursive = true;
        # Broken in nix 2.18.2
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/git/github/albinvass/nixos/tools";
      };
      ".bazelrc".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/git/github/albinvass/nixos/home-manager/modules/devtools/bazel/.bazelrc";
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
        enableZshIntegration = true;
      };
      ripgrep.enable = true;
      k9s.enable = true;
      direnv = {
        enable = true;
        enableZshIntegration = true;
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
      btop.enable = true;
      eza = {
        enable = true;
        enableZshIntegration = true;
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
        enableZshIntegration = true;
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
            extraConfig = # tmux
              ''
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
        ];
        extraConfig = # tmux
          ''
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
          '';
      };
      zoxide = {
        enable = true;
        enableZshIntegration = true;
      };
    };

    home.sessionVariables = {
      NH_FLAKE = pkgs.lib.mkDefault "${config.home.homeDirectory}/git/github/albinvass/nixos";
    };

    home.packages = with pkgs; [
      archivemount
      acpi
      atool
      azure-cli
      buildozer
      dig
      libarchive
      docker-compose
      python311
      virtualenv
      rustup
      yarn
      cloc
      lsof
      cmake
      gnumake
      gcc
      yq
      gnupg
      rsync
      vault
      whois
      sops
      killall
      openssl
      ssh-to-age
      ssh-to-pgp
      shellcheck
      unrar
      tldr
      dust
      duf
      parted
      cloud-utils
      restic
      fzf
      statix
      jless
      devenv
      watchexec
      inputs.nh.packages.${pkgs.system}.default
      git-toprepo
    ];
  };
}
