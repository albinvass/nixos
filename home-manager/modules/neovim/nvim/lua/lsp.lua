local nvim_lsp = require('lspconfig')

local format_on_close = function()
  vim.api.nvim_create_autocmd({"BufWritePre"}, {
      callback = function()vim.lsp.buf.format { async = false }end
  })
end

-- See:
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
local servers = {
  bacon_ls={
    init_options = {
      updateOnSave = true,
      updateOnSaveMillis = 1000,
    }
  },
  esbonio={},
  lua_ls={
    settings = {
      Lua = {
        hint = { enable = true },
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
  gopls={
    on_attach=format_on_close,
    settings={
      gopls={
        completeUnimported = true,
        staticcheck = true,
        hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
        },
      }
    }
  },
  marksman={},
  pyright={
    settings = {
      python = {
        analysis = {
          reportIncompatibleMethodOverride = true,
        },
      },
    },
  },
  bashls={},
  --dockerls={},
  clangd={},
  starpls={},
  terraformls={
    on_attach=function()
      format_on_close()
    end
  },
  yamlls={},
  rust_analyzer={
    checkOnSave = {
     enable = false,
    },
    diagnostics = {
      enable = false,
    },
  },
}

for lsp, conf in pairs(servers) do
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
    vim.keymap.set('n', '<Leader>ih', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, opts)
  end
})
