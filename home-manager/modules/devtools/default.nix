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
    albinvass.tmux.enable = true;

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
      "nh-switch" =
        if pkgs.stdenv.isLinux then
          (if config.submoduleSupport.enable then "nh os switch" else "nh home switch")
        else
          "nh darwin switch";
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
        enableDefaultConfig = false;
        matchBlocks = {
          "*" = {
            identityFile = [
              "~/.ssh/id_rsa"
              "~/.ssh/id_ed25519"
              "~/.ssh/id_ed25519_sk_red"
              "~/.ssh/id_ed25519_sk_green"
            ];
          };
        };
        includes = [ "~/.ssh/local_config" ];
      };
      yazi = {
        enable = true;
        enableFishIntegration = false;
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
        archivemount
        atool
        bazelIsBazelisk
        buildozer
        claude-code
        copilot-cli
        opencode
        cloud-utils
        devenv
        dig
        docker-compose
        duf
        dust
        fzf
        gnumake
        gnupg
        jless
        killall
        libarchive
        lsof
        nh
        openssl
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
      ]
      ++ (
        if pkgs.stdenv.isLinux then
          [
            acpi
            parted
          ]
        else
          [ ]
      );
  };
}
