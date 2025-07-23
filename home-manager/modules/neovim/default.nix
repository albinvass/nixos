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
      extraPackages = with pkgs; [
        tree-sitter
        bacon
        bacon-ls
        nil
        cargo
        llvmPackages.clang-unwrapped
        lua-language-server
        terraform-ls
        helm-ls
        nodePackages.bash-language-server
        vscode-langservers-extracted
        shellcheck
        gopls
        go-tools
        pyright
        sqls
        marksman
        ripgrep
        git
        yaml-language-server
        starpls-bin
        delve
        rr
        vscode-extensions.ms-vscode.cpptools
      ];

      extraPython3Packages = (
        ps: with ps; [
          debugpy
        ]
      );

      plugins = with pkgs.vimPlugins; [
        codecompanion-nvim
        nvim-surround
        catppuccin-nvim
        vimagit
        vim-fugitive
        vim-helm
        vim-rooter
        popup-nvim
        plenary-nvim
        nvim-lspconfig
        telescope-nvim
        vim-snippets
        cmp-nvim-lsp
        cmp-buffer
        cmp-cmdline
        cmp-path
        nvim-cmp
        luasnip
        cmp_luasnip
        nvim-treesitter.withAllGrammars
        nvim-treesitter-textobjects
        nvim-web-devicons
        vim-markdown
        markdown-preview-nvim
        gitsigns-nvim
        trouble-nvim
        whitespace-nvim
        dressing-nvim
        yazi-nvim
        nvim-dap
        nvim-dap-ui
        nvim-dap-rr
        nvim-dap-python
        nvim-dap-go
      ];
    };
  };
}
