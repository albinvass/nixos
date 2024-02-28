local nvim_lsp = require('lspconfig')
-- See:
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
local servers = {
  lua_ls={
    settings = {
      Lua = {
        diagnostics = {
	  globals = { 'vim' }
	}
      }
    }
  },
  sqls={},
  helm_ls={},
  nil_ls={},
  eslint={},
  gopls={},
  marksman={},
  pyright={},
  bashls={},
  --dockerls={},
  clangd={},
  terraformls={_on_attach=function()
	  vim.api.nvim_create_autocmd({"BufWritePre"}, {
	      pattern = {"*.tf", "*.tfvars"},
	      callback = vim.lsp.buf.formatting_sync
	  })
      end
  },
}

for lsp, conf in pairs(servers) do
  conf['on_attach'] = function()
      if conf['_on_attach'] ~= nil then
	  conf._on_attach()
      end
  end
  conf['flags'] = {
      debounce_text_changes = 150,
  }
  nvim_lsp[lsp].setup(conf)
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function (ev)
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end
})
