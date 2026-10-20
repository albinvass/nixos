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
    albinvass.xonsh.enable = true;

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

    xdg.configFile."opencode/opencode.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/home-manager/modules/devtools/opencode/opencode.json";

    xdg.configFile."opencode/opencode.json".force = true;

    # Custom "pi" agent for ralph (@th0rgal/ralph-wiggum). Uses the generic
    # args template ([--model M] [--full-auto] [extra...] PROMPT); the adapter
    # drops --full-auto (pi has no permission prompts) and runs in print mode.
    xdg.configFile."open-ralph-wiggum/agents.json".text = builtins.toJSON {
      version = "1.0";
      agents = [
        {
          type = "pi";
          configName = "Pi";
          command = "${pkgs.writeShellScript "ralph-pi" ''
            args=()
            model=0
            for arg in "$@"; do
              [ "$arg" = "--model" ] && model=1
              [ "$arg" = "--full-auto" ] || args+=("$arg")
            done
            # Default model for ralph loops unless --model was given
            [ "$model" = 1 ] || args=(--model github-copilot/claude-opus-5.5 "''${args[@]}")
            exec ${pkgs.pi-coding-agent}/bin/pi -p "''${args[@]}"
          ''}";
          argsTemplate = "default";
          envTemplate = "default";
          parsePattern = "default";
        }
      ];
    };

    home.shellAliases = {
      "nh-switch" =
        if pkgs.stdenv.hostPlatform.isLinux then
          (if config.submoduleSupport.enable then "nh os switch" else "nh home switch")
        else
          "nh darwin switch";
      "cd" = "z";
    };

    programs = {
      starship = {
        enable = true;
        enableFishIntegration = config.albinvass.fish.enable;
        settings =
          let
            flavour = "mocha";
          in
          {
            add_newline = true;
            palette = "catppuccin_${flavour}";
            command_timeout = 100;
            aws = {
              disabled = true;
            };
            python = {
              disabled = true;
            };
            git_status = {
              disabled = true;
            };
          }
          // fromTOML (builtins.readFile "${inputs.catppuccin-starship}/themes/${flavour}.toml");
      };
      taskwarrior = {
        enable = true;
      };
      bacon.enable = true;
      nix-index-database.comma.enable = true;
      awscli.enable = true;
      fzf = {
        enable = true;
        enableFishIntegration = false;
      };
      television = {
        enable = true;
        enableFishIntegration = config.albinvass.fish.enable;
        channels = lib.mkIf config.albinvass.xonsh.enable {
          xonsh-history = {
            metadata = {
              name = "xonsh-history";
              description = "A channel to select from your xonsh history";
              requirements = [ "jq" ];
            };
            source = {
              command = ''cat "''${XONSH_DATA_DIR:-$HOME/.local/share/xonsh}"/history_json/*.json | jq -r '.data.cmds[].inp | rtrimstr("\n")' | tac'';
              shell = "bash";
            };
          };
        };
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
          paging = "always";
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
        icons = "auto";
      };
      go.enable = true;
      jq.enable = true;
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            IdentityFile = [
              "~/.ssh/id_rsa"
              "~/.ssh/id_ed25519"
              "~/.ssh/id_ed25519_sk_red"
              "~/.ssh/id_ed25519_sk_green"
            ];
          };
        };
        includes = [ "~/.ssh/local_config" ];
      };
      fd = {
        enable = true;
      };
      yazi = {
        enable = true;
        enableFishIntegration = false;
        shellWrapperName = "y";
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
      NH_FLAKE = lib.mkDefault config.albinvass.gitDirectory;
    };

    home.sessionPath = [
      "$HOME/.npm-global/bin"
      "$HOME/.opencode/bin"
    ];

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
        ralph =
          let
            src = fetchzip {
              url = "https://registry.npmjs.org/@th0rgal/ralph-wiggum/-/ralph-wiggum-1.2.2.tgz";
              hash = "sha256-Ac7SwbwNeVitKLmJunIos8iTCRM/kkuAHO6hxcgQTVo=";
            };
          in
          # Default to pi unless an agent/rotation is given explicitly.
          writeShellScriptBin "ralph" ''
            for arg in "$@"; do
              case "$arg" in
                --agent | --rotation | --) exec ${pkgs.bun}/bin/bun ${src}/ralph.ts "$@" ;;
              esac
            done
            exec ${pkgs.bun}/bin/bun ${src}/ralph.ts --agent pi "$@"
          '';
      in
      with pkgs;
      [
        atool
        bazelIsBazelisk
        buildozer
        cloud-utils
        devenv
        dig
        docker-compose
        duf
        dust
        flameshot
        fzf
        gnumake
        gnupg
        hyperfine
        jless
        killall
        libarchive
        lsof
        nh
        nodejs
        openssh
        openssl
        pi-coding-agent
        ralph
        uv
        restic
        rsync
        ruff
        rustup
        s
        sesh
        shellcheck
        sops
        ssh-to-age
        ssh-to-pgp
        statix
        tldr
        tokei
        ty
        unrar
        virtualenv
        watchexec
        whois
        yq
        xz
        lld
        zola
      ]
      ++ (
        if pkgs.stdenv.hostPlatform.isLinux then
          [
            acpi
            parted
          ]
        else
          [ ]
      );
  };
}
