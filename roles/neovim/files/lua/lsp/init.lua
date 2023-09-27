local present, _ = pcall(require, "lspconfig")
if not present then return end

require("lsp.config")
require("lsp.handlers").setup()
