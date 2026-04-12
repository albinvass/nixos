vim.cmd.colorscheme "catppuccin-mocha"
vim.o.number = true
vim.o.showcmd = true
vim.o.cursorline = true
vim.o.wildmenu = true
vim.o.lazyredraw = true
vim.o.showmatch = true
vim.o.hlsearch = true
vim.o.colorcolumn = "80"
vim.o.mouse = nil
vim.g.mapleader = " "
vim.g.maplocalleader = ","
local filetype_config = {
  bash       = {},
  hcl        = {},
  helm       = {},
  json       = {},
  lua        = {},
  markdown   = {},
  nix        = {},
  norg       = {},
  terraform  = {},
  yaml       = {},
  bzl        = { indent = 4 },
  c          = { indent = 4 },
  cpp        = { indent = 4 },
  dockerfile = { indent = 4 },
  go         = { indent = 4 },
  python     = { indent = 4 },
}
vim.api.nvim_create_autocmd('FileType', {
  pattern = vim.tbl_keys(filetype_config),
  callback = function(args)
    local config = filetype_config[args.match]
    local indent = config.indent or 2
    vim.bo.tabstop = indent
    vim.bo.shiftwidth = indent
    vim.bo.softtabstop = indent
    vim.bo.expandtab = true
    vim.treesitter.start()
  end,
})

vim.cmd 'highlight Normal guibg=NONE ctermbg=NONE'

vim.keymap.set("n","<leader> ", vim.cmd.nohlsearch)

require("snacks").setup({
  input = { enabled = true },
  terminal = { enabled = true },
})
require("nvim-surround").setup{}
require('csvview').setup()

vim.diagnostic.config({ virtual_text = true })
-- keybinds
vim.keymap.set("n", "gK", function()
  local new_config = not vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({ virtual_lines = new_config })
end, { desc = 'Toggle diagnostic virtual_lines' })
vim.keymap.set("n", "<leader>xx", function() require("trouble").toggle("diagnostics") end)
vim.keymap.set("n", "<C-n>",      function() require("trouble").toggle("symbols") end)
vim.keymap.set("n", "<leader>xw", function() require("trouble").toggle("workspace_diagnostics") end)
vim.keymap.set("n", "<leader>xd", function() require("trouble").toggle("document_diagnostics") end)
vim.keymap.set("n", "<leader>xq", function() require("trouble").toggle("quickfix") end)
vim.keymap.set("n", "<leader>xl", function() require("trouble").toggle("loclist") end)
vim.keymap.set("n", "gR", function() require("trouble").toggle("lsp_references") end)


-- Enabled opening telescope results in trouble window
local actions = require("telescope.actions")
local open_with_trouble = require("trouble.sources.telescope").open
local add_to_trouble = require("trouble.sources.telescope").add
local telescope = require("telescope")


local git_root = function()
  return vim.fn.systemlist("git rev-parse --show-toplevel")[1]
end
local telescope_builtin = require("telescope.builtin")
vim.keymap.set(
  "n",
  "<C-p>",
  function()
    telescope_builtin.find_files({
      cwd = git_root()
    })
  end
)
vim.keymap.set(
  "n",
  "<C-e>",
  function()
    telescope_builtin.live_grep({
      cwd = git_root()
    })
  end
)

local telescopeConfig = require("telescope.config")
local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
table.insert(vimgrep_arguments, "--hidden")
table.insert(vimgrep_arguments, "--glob")
table.insert(vimgrep_arguments, "!**/.git/*")

telescope.setup({
  defaults = {
    vimgrep_arguments = vimgrep_arguments,
    layout_strategy = "bottom_pane",
  },
  extensions = {
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    }
  }
})
require('telescope').load_extension('fzf')

vim.filetype.add({ extension = { conflist = 'json' } })


require('whitespace-nvim').setup()
-- remove trailing whitespace with a keybinding
vim.keymap.set('n', '<Leader>t', require('whitespace-nvim').trim)

require('gitsigns').setup({
  current_line_blame = true,
})
-- Fix: https://github.com/LunarVim/darkplus.nvim/pull/25/files
vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", {fg = "DarkGrey", bg = 'NONE'})


vim.keymap.set("n", "<leader>-", function()
  require("yazi").yazi()
end)

require("ibl").setup()

-- Required for `opts.events.reload`.
vim.o.autoread = true

-- Leap
vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap)')
vim.keymap.set('n',             'S', '<Plug>(leap-from-window)')
