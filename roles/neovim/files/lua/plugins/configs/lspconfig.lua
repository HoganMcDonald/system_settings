-----------------------------------------------------------
-- LSP configuration file
-----------------------------------------------------------

-- Plugin: lspconfig
-- https://github.com/neovim/nvim-lspconfig

-- available servers:
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
local servers = {
  'solargraph', -- ruby
  'vuels', -- vue
  'eslint',
}

local nvim_lsp = require('lspconfig')
local api = vim.api
local lsp = vim.lsp

local capabilities = lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.documentationFormat = { 'markdown', 'plaintext' }
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.preselectSupport = true
capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
capabilities.textDocument.completion.completionItem.deprecatedSupport = true
capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
capabilities.textDocument.completion.completionItem.tagSupport = { valueSet = { 1 } }
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    'documentation',
    'detail',
    'additionalTextEdits',
  },
}

local on_attach = function(_, bufnr)
  local function buf_set_option(...)
    api.nvim_buf_set_option(bufnr, ...)
  end

  --Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
  require('core.keymaps').lspconfig(bufnr)
end

for _, language in ipairs(servers) do
  nvim_lsp[language].setup({
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {
      debounce_text_changes = 150,
    },
  })
end
