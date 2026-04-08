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
    xdg.configFile."nvim/lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/home-manager/modules/neovim/nvim/lua";
    xdg.configFile."nvim/after".source =
      config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/home-manager/modules/neovim/nvim/after";
    xdg.configFile."nvim/ftdetect".source =
      config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/home-manager/modules/neovim/nvim/ftdetect";
    xdg.configFile."nvim/ftplugin".source =
      config.lib.file.mkOutOfStoreSymlink "${config.albinvass.gitDirectory}/home-manager/modules/neovim/nvim/ftplugin";
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      extraLuaConfig = builtins.readFile ./nvim/init.lua;
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
          bash-language-server
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

      extraPython3Packages =
        ps: with ps; [
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
