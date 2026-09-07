local pack = require("lib.pack")

-- Richer code-action UI than the default vim.ui.select prompt. Uses the
-- snacks picker you already have; delta renders the diff preview.
-- `<leader>ca` is taken over in core/lsp.lua.
return {
  src = pack.github("rachartier/tiny-code-action.nvim"),
  dependencies = pack.github("folke/snacks.nvim"),
  event = "LspAttach",
  config = function()
    require("tiny-code-action").setup({
      picker = "snacks",
      backend = "delta",
    })
  end,
}
