-----------------------------------------------------------
-- autotag configuration file
-----------------------------------------------------------

-- Plugin: autotag
-- https://github.com/windwp/nvim-ts-autotag

local lsp = vim.lsp

require('nvim-ts-autotag').setup()

-- lsp.handlers['textDocument/publishDiagnostics'] = lsp.with(
--   lsp.diagnostic.on_publish_diagnostics,
--   {
--     underline = true,
--     virtual_text = {
--       spacing = 5,
--       severity_limit = 'Warning',
--     },
--     update_in_insert = true,
--   }
-- )
