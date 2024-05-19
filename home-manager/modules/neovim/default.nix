{ config, pkgs, lib, inputs, ...}:
{
  home.file."${config.xdg.configHome}/nvim" = {
    source = ./nvim;
    recursive = true;
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
    extraPackages = with pkgs; [
      tree-sitter
      nil
      llvmPackages.clang-unwrapped
      lua-language-server
      terraform-ls
      helm-ls
      nodePackages.bash-language-server
      vscode-langservers-extracted
      shellcheck
      gopls
      go-tools
      nodePackages.pyright
      sqls
      marksman
      ripgrep
      git
    ];

    plugins = with pkgs.vimPlugins; [
      vim-surround
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
      neorg
      neorg-telescope
      nvim-cmp
      luasnip
      cmp_luasnip
      nvim-treesitter.withAllGrammars
      nvim-treesitter-textobjects
      nvim-web-devicons
      nvim-FeMaco-lua
      vim-markdown
      markdown-preview-nvim
      gitsigns-nvim
      trouble-nvim
      whitespace-nvim
      neo-tree-nvim
    ];

    # Automatically require all toplevel lua scripts
    extraLuaConfig =
      let
        luaFiles = 
          let
            luaDir = builtins.readDir ./nvim/lua;
            onlyFiles = n: v: v == "regular";
          in builtins.attrNames (lib.attrsets.filterAttrs onlyFiles luaDir);
        mkRequire = path: 
          let
            filePath = toString path;
            requireName = lib.strings.removeSuffix ''.lua'' filePath;
          in "require'${requireName}'";
      in lib.strings.concatMapStrings (s: s + "\n") (map mkRequire luaFiles);
  };
}
