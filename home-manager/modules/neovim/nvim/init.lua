require'base'
require'completion'
require'femaco-setup'
require'lsp'
require'tree-sitter'

require("dap-python").setup(vim.g.python3_host_prog)
require("dapui").setup()
