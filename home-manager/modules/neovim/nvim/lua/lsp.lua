local format_augroup = vim.api.nvim_create_augroup('UserLspFormatOnSave', {})

local format_on_save = function(bufnr)
  vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = format_augroup,
    buffer = bufnr,
    callback = function()
      vim.lsp.buf.format({ async = false, bufnr = bufnr })
    end,
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
  nixd={
    settings = {
      nixd = {
        formatting = {
          command = { "nixfmt" },
        },
      },
    },
  },
  eslint={},
  gopls={
    on_attach=function(_, bufnr)
      format_on_save(bufnr)
    end,
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
    on_attach=function(_, bufnr)
      format_on_save(bufnr)
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
  vim.lsp.config[lsp] = conf
  vim.lsp.enable(lsp)
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
    vim.keymap.set('n', '<leader>f', function()
      vim.lsp.buf.format({ async = true, bufnr = ev.buf })
    end, { buffer = ev.buf, desc = 'Format buffer with LSP' })
    vim.keymap.set('n', '<Leader>ih', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, opts)
  end
})
