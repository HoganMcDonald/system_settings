local fn = vim.fn
local lsp = vim.lsp
local diagnostic = vim.diagnostic
local keymap = vim.keymap

local M  = {}

M.setup = function()
  local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn", text = "" },
    { name = "DiagnosticSignHint", text = "" },
    { name = "DiagnosticSignInfo", text = "" },
  }

  for _, sign in ipairs(signs) do
    fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
  end

  diagnostic.config({
    virtual_text = false,
    signs = { active = signs },
    update_in_insert = true,
    underline = false,
    severity_sort = true,
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  })

  lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, {
    border = "rounded",
  })

  lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, {
    border = "rounded",
  })
end

local function lsp_keymaps(bufnr)
  local opts = { silent = true, remap = false, buffer = bufnr }

  -- Generate LSP functionality
  keymap.set("n", "K",  lsp.buf.hover, opts)
  keymap.set("n", "ge", lsp.buf.rename, opts)
  keymap.set("n", "gd", lsp.buf.definition, opts)
  keymap.set("n", "gD", lsp.buf.declaration, opts)
  keymap.set("n", "gi", lsp.buf.implementation, opts)
  keymap.set("n", "gt", lsp.buf.type_definition, opts)

  -- Navigate diagnostics errors/mesages
  keymap.set("n", "gk", diagnostic.goto_next, opts)
  keymap.set("n", "gj", diagnostic.goto_prev, opts)

  -- Telescope helpers for listing symbols and diagnostics
  keymap.set("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", opts)
  keymap.set("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", opts)
end

M.on_attach = function(_, bufnr)
  lsp_keymaps(bufnr)
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true
}

M.capabilities = capabilities

return M
