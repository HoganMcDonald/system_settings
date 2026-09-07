local pack = require("lib.pack")

-- Generates doc-comment skeletons (EmmyLua, JSDoc/TSDoc, Google docstrings,
-- YARD, ...) for the function/class under the cursor, treesitter-driven.
-- Lazy-loaded via `:Neogen` and the generate key. The `nvim` snippet engine
-- makes the inserted placeholders navigable without an extra snippet plugin.
return {
  src = pack.github("danymat/neogen"),
  cmd = "Neogen",
  keys = {
    { "<leader>cd", function() require("neogen").generate() end, desc = "Generate doc comment" },
  },
  config = function()
    require("neogen").setup({
      snippet_engine = "nvim",
    })
  end,
}
