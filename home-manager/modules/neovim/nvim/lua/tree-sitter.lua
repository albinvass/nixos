require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true
  },
  indent = {
    enable = true
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<Leader>ss";
      node_incremental = "<Leader>si";
      scope_incremental = "<Leader>sc";
      node_decremental = "<Leader>sd";
    },
  },
}
