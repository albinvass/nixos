{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.albinvass.neovim;
in
{
  options.albinvass.neovim = {
    enable = lib.mkEnableOption "Enable Neovim";
  };
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.nixneovimplugins.overlays.default
    ];
    home.file."${config.xdg.configHome}/nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/home-manager/modules/neovim/nvim";
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      withNodeJs = true;
      withPython3 = true;
      withRuby = true;
      extraPackages =
        with pkgs;
        [
          bacon
          bacon-ls
          cargo
          delve
          git
          go-tools
          gopls
          helm-ls
          llvmPackages.clang-unwrapped
          lua-language-server
          marksman
          nixd
          nodePackages.bash-language-server
          pyright
          ripgrep
          shellcheck
          sqls
          starpls
          terraform-ls
          tree-sitter
          vscode-extensions.ms-vscode.cpptools
          vscode-langservers-extracted
          yaml-language-server
        ]
        ++ (if pkgs.stdenv.isLinux then [ rr ] else [ ]);

      extraPython3Packages = ps: with ps; [
          debugpy
        ];

      plugins = with pkgs.vimPlugins; [
        catppuccin-nvim
        cmp-buffer
        cmp-cmdline
        cmp-nvim-lsp
        cmp-path
        cmp_luasnip
        csvview-nvim
        gitsigns-nvim
        indent-blankline-nvim
        leap-nvim
        luasnip
        markdown-preview-nvim
        nvim-cmp
        nvim-dap
        nvim-dap-go
        nvim-dap-python
        nvim-dap-rr
        nvim-dap-ui
        nvim-lspconfig
        nvim-surround
        nvim-treesitter-textobjects
        nvim-treesitter.withAllGrammars
        nvim-web-devicons
        opencode-nvim
        plenary-nvim
        snacks-nvim
        telescope-fzf-native-nvim
        telescope-nvim
        trouble-nvim
        vim-fugitive
        vim-helm
        vim-markdown
        vim-rooter
        vim-snippets
        vimagit
        whitespace-nvim
        yazi-nvim
      ];
    };
  };
}
