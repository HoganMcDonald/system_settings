local M = {}

function M.setup()
  local present, _ = pcall(require, 'lspconfig')
  if not present then
    return
  end

  require('lsp.config').setup()
  -- require('lsp.handlers').setup()
end

return M
