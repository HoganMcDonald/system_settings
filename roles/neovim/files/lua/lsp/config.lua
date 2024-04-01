local M = {}

function M.mason_setup()
  local present, mason = pcall(require, 'mason')
  if not present then
    vim.notify('Couldn\'t load Mason' .. mason, vim.log.levels.ERROR)
    return
  end

  mason.setup()
end

function M.mason_lspconfig_setup()
  require('mason-lspconfig').setup {
    ensure_installed = {
      'bashls',
      'cssls',
      'html',
      'jsonls',
      'solargraph',
      'sqlls',
      'lua_ls',
    },
  }
end

function M.setup()
  M.mason_setup()
  M.mason_lspconfig_setup()

  local defaults = {
    on_attach = require('lsp.handlers').on_attach,
    capabilities = require('lsp.handlers').capabilities,
  }

  local lspconfig_ok, lspconfig = pcall(require, 'lspconfig')
  if not lspconfig_ok then
    vim.notify('Couldn\'t load LSP-Config' .. lspconfig, vim.log.levels.ERROR)
    return
  end

  require('mason-lspconfig').setup_handlers {
    function(server_name)
      lspconfig[server_name].setup(defaults)
    end,
    ['lua_ls'] = function()
      lspconfig.lua_ls.setup(vim.tbl_deep_extend('force', require 'lsp.settings.lua_ls', defaults))
    end,
    ['solargraph'] = function()
      lspconfig.solargraph.setup(vim.tbl_deep_extend('force', require 'lsp.settings.solargraph', defaults))
    end,
    ['jsonls'] = function()
      lspconfig.jsonls.setup(vim.tbl_deep_extend('force', require 'lsp.settings.jsonls', defaults))
    end,
  }
end

return M
