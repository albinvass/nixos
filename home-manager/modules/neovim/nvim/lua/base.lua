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

require("aerial").setup{}
require("nvim-surround").setup{}
require("neo-tree").setup{}
vim.api.nvim_set_keymap("n", "<C-n>", ":Neotree toggle<CR>", {})

-- keybinds
vim.keymap.set("n", "<leader>xx", function() require("trouble").toggle("diagnostics") end)
vim.keymap.set("n", "<leader>xw", function() require("trouble").toggle("workspace_diagnostics") end)
vim.keymap.set("n", "<leader>xd", function() require("trouble").toggle("document_diagnostics") end)
vim.keymap.set("n", "<leader>xq", function() require("trouble").toggle("quickfix") end)
vim.keymap.set("n", "<leader>xl", function() require("trouble").toggle("loclist") end)
vim.keymap.set("n", "gR", function() require("trouble").toggle("lsp_references") end)

vim.filetype.add({ extension = { conflist = 'json' } })


require('whitespace-nvim').setup()
-- remove trailing whitespace with a keybinding
vim.keymap.set('n', '<Leader>t', require('whitespace-nvim').trim)

require('neorg').setup{
  load = {
    ["core.defaults"] = {},
    ["core.concealer"] = {},
    ["core.dirman"] = {
      config = {
        workspaces = {
          notes = "~/notes",
        },
        default_workspace = "notes",
      },
    },
  }
}

require('gitsigns').setup({
  current_line_blame = true,
})
-- Fix: https://github.com/LunarVim/darkplus.nvim/pull/25/files
vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", {fg = "DarkGrey", bg = 'NONE'})


vim.keymap.set("n", "<leader>-", function()
  require("yazi").yazi()
end)
