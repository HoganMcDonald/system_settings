-----------------------------------------------------------
-- mason configuration file
-----------------------------------------------------------

-- Plugin: mason
-- https://github.com/williamboman/mason.nvim

local present, mason = pcall(require, 'mason')

if not present then
  return
end

mason.setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    }
  }
})

require("mason-lspconfig").setup({
  ensure_installed = {
    "bashls",
    "cssls",
    "dockerls",
    "html",
    "jsonls",
    "lemminx",
    "solargraph",
    "sqlls",
    "sumneko_lua",
    "tsserver",
    "yamlls",
  },
})
