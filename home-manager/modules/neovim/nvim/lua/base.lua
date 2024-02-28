vim.cmd.colorscheme "catppuccin-mocha"
vim.o.number = true
vim.o.showcmd = true
vim.o.cursorline = true
vim.o.wildmenu = true
vim.o.lazyredraw = true
vim.o.showmatch = true
vim.o.hlsearch = true
vim.o.colorcolumn = 80
vim.o.mouse = nil
vim.g.mapleader = ","
vim.o.indent = true
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.expandtab = true
vim.bo.softtabstop = 2

vim.cmd 'highlight Normal guibg=NONE ctermbg=NONE'

vim.api.nvim_set_keymap("n", "<Leader> ", ":nohlsearch<CR>", {})
vim.api.nvim_set_keymap("n", "<C-p>", ":Telescope find_files<CR>", {})
vim.api.nvim_set_keymap("n", "<C-e>", ":Telescope live_grep<CR>", {})

local builtin = require("nnn").builtin
require'nnn'.setup{
  mappings = {
    { "<C-t>", builtin.open_in_tab },       -- open file(s) in tab
    { "<C-s>", builtin.open_in_split },     -- open file(s) in split
    { "<C-v>", builtin.open_in_vsplit },    -- open file(s) in vertical split
    { "<C-y>", builtin.copy_to_clipboard }, -- copy file(s) to clipboard
    { "<C-w>", builtin.cd_to_path },        -- cd to file directory
    { "<C-e>", builtin.populate_cmdline },  -- populate cmdline (:) with file(s)
  }
}
vim.api.nvim_set_keymap("n", "<C-n>", ":NnnExplorer<CR>", {})

require('gitsigns').setup({
  current_line_blame = true,
})
