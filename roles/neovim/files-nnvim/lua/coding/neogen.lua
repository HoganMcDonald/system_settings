local pack = require("lib.pack")

-- Generates doc-comment skeletons (EmmyLua, JSDoc/TSDoc, Google docstrings,
-- YARD, ...) for the function/class under the cursor, treesitter-driven.
-- Lazy-loaded via `:Neogen` and the generate key.
-- Snippet expansion is left off: the nvim engine inserts via vim.snippet,
-- whose mid-edit nvim_buf_set_lines races Neovim 0.12's document_color module
-- (assert in Provider:request) when an LSP with documentColor support is
-- attached. The plain-text skeleton is still fully editable by hand.
return {
  src = pack.github("danymat/neogen"),
  cmd = "Neogen",
  keys = {
    { "<leader>cd", function() require("neogen").generate() end, desc = "Generate doc comment" },
  },
  config = function()
    require("neogen").setup()
  end,
}
