local M = {}

function M.setup()
  local lsp_present, _ = pcall(require, 'lspconfig')
  if not lsp_present then
    return
  end

  local mason_present, _ = pcall(require, 'mason')
  if not mason_present then
    return
  end

  local mason_lspconfig_present, _ = pcall(require, 'mason-lspconfig')
  if not mason_lspconfig_present then
    return
  end

  require('lsp.config').setup()
  require('lsp.handlers').setup()
end

return M
