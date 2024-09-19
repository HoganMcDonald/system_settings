local M = {}

M.setup = function()
  local signs = {
    [vim.diagnostic.severity.ERROR] = '',
    [vim.diagnostic.severity.WARN] = '',
    [vim.diagnostic.severity.HINT] = '',
    [vim.diagnostic.severity.INFO] = '',
  }

  vim.diagnostic.config {
    virtual_text = false, -- virtual text
    virtual_lines = false, -- lsp lines
    signs = {
      text = signs,
    },
    underline = true, -- underlines
    update_in_insert = false,
    severity_sort = true,
    float = {
      focusable = false,
      style = 'minimal',
      border = 'rounded',
      source = 'if_many',
      header = '',
      prefix = '',
    },
  }

  vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = 'rounded',
  })

  vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = 'rounded',
  })
end

local function lsp_keymaps(bufnr)
  local opts = { silent = true, remap = false, buffer = bufnr }

  -- Generate LSP functionality
  -- vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  -- vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  -- vim.keymap.set('n', '<leader>bf', vim.lsp.buf.format, opts)
  vim.keymap.set(
    'n',
    '<leader>lh',
    vim.lsp.buf.signature_help,
    { desc = 'signature help', silent = true, remap = false, buffer = bufnr }
  )
  vim.keymap.set('n', 'ge', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)

  -- Navigate diagnostics errors/mesages
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
end

M.on_attach = function(_, bufnr)
  lsp_keymaps(bufnr)
end

local has_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
local capabilities = vim.tbl_deep_extend(
  'force',
  {},
  vim.lsp.protocol.make_client_capabilities(),
  has_cmp and cmp_nvim_lsp.default_capabilities() or {},
  {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  }
)

M.capabilities = capabilities

return M
