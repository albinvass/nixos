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
--vim.opt.indent = true
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.expandtab = true
vim.bo.softtabstop = 2

vim.cmd 'highlight Normal guibg=NONE ctermbg=NONE'

vim.api.nvim_set_keymap("n", "<Leader> ", ":nohlsearch<CR>", {})
vim.api.nvim_set_keymap("n", "<C-p>", ":Telescope find_files<CR>", {})
vim.api.nvim_set_keymap("n", "<C-e>", ":Telescope live_grep<CR>", {})

require("nvim-surround").setup{}

-- keybinds
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
telescope.setup({
  defaults = {
    mappings = {
      i = { ["<c-t>"] = open_with_trouble },
      n = { ["<c-t>"] = open_with_trouble },
    },
  },
})

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
