local present, mason = pcall(require, "mason")
if not present then
  vim.notify("Couldn't load Mason" .. mason, "error")
  return
end

mason.setup()

require("mason-lspconfig").setup({
  ensure_installed = {
    "bashls",
    "cssls",
    "html",
    "jsonls",
    "solargraph",
    "sqlls",
    "lua_ls",
    "yamlls",
  },
})

local defaults = {
  on_attach = require("lsp.handlers").on_attach,
  capabilities = require("lsp.handlers").capabilities,
}

local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_ok then
  vim.notify("Couldn't load LSP-Config" .. lspconfig, "error")
  return
end
local coq = require "coq"

require("mason-lspconfig").setup_handlers {
  function(server_name)
    lspconfig[server_name].setup(coq.lsp_ensure_capabilities(defaults))
  end,
  ['lua_ls'] = function()
    lspconfig.lua_ls.setup(coq.lsp_ensure_capabilities(vim.tbl_deep_extend("force", require("lsp.settings.lua_ls"), defaults)))
  end,
  ['solargraph'] = function()
    lspconfig.solargraph.setup(coq.lsp_ensure_capabilities(vim.tbl_deep_extend("force",
      require("lsp.settings.solargraph"), defaults)))
  end,
  ['jsonls'] = function()
    lspconfig.jsonls.setup(coq.lsp_ensure_capabilities(vim.tbl_deep_extend("force", require("lsp.settings.jsonls"),
      defaults)))
  end,
}
