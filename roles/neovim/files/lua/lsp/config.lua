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
      'marksman', -- markdown
      'bashls',
      'cssls',
      'html',
      'jsonls',
      'sqlls',
      'lua_ls',
      'rust_analyzer', -- Add rust_analyzer
      'yamlls',
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

  -- Setup LSP servers directly bypassing mason-lspconfig
  lspconfig.rust_analyzer.setup(defaults)
  lspconfig.lua_ls.setup(vim.tbl_deep_extend('force', require 'lsp.settings.lua_ls', defaults))
  lspconfig.solargraph.setup(vim.tbl_deep_extend('force', require 'lsp.settings.solargraph', defaults))
  lspconfig.jsonls.setup(vim.tbl_deep_extend('force', require 'lsp.settings.jsonls', defaults))
  lspconfig.yamlls.setup(vim.tbl_deep_extend('force', require 'lsp.settings.yamlls', defaults))
  lspconfig.bashls.setup(defaults)
  lspconfig.cssls.setup(defaults)
  lspconfig.html.setup(defaults)
  lspconfig.marksman.setup(defaults)
end

return M
