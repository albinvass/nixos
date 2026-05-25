
require('nvim-treesitter-textobjects')
require('nvim-treesitter.config').setup({
  highlight = {
    enable = true
  },
  indent = {
    enable = true,
    disable = { "yaml" }
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

-- Register the parser so :TSInstall xonsh works
vim.api.nvim_create_autocmd('User', {
  pattern = 'TSUpdate',
  callback = function()
    require('nvim-treesitter.parsers').xonsh = {
      install_info = {
        url = 'https://github.com/FoamScience/tree-sitter-xonsh',
        queries = 'queries/',
      },
    }
  end,
})
