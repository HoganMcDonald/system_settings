-----------------------------------------------------------
-- mason lspconfig configuration file
-----------------------------------------------------------

-- Plugin: mason-lspconfig
-- https://github.com/williamboman/mason-lspconfig.nvim

local present, mlc = pcall(require, 'mason-lspconfig')

if not present then
  return
end

mlc.setup({
  ensure_installed = {
    "sumneko_lua",
    "rust_analyzer",
    "solargraph",
    "eslint"
  }
})
