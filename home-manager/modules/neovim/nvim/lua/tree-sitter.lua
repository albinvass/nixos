require('nvim-treesitter-textobjects')
require('nvim-treesitter.configs').setup({
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
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },

      selection_modes = {
        ["@parameter.outer"] = "v",
        ["@function.outer"] = "v",
        ["@class.outer"] = "v",
      },

      include_surrounding_whitespace = true,
    },
  },
})
