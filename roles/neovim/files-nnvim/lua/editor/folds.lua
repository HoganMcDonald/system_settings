local pack = require("lib.pack")

return {
  {
    src = pack.github("chrisgrieser/nvim-origami"),
    config = function()
      require("origami").setup({
        autoFold = { enabled = false },
      })
    end,
  },
  {
    src = pack.github("jghauser/fold-cycle.nvim"),
    config = function()
      local fold_cycle = require("fold-cycle")

      fold_cycle.setup()

      vim.keymap.set("n", "zo", fold_cycle.open, { silent = true, desc = "Open next fold level" })
      vim.keymap.set("n", "zc", fold_cycle.close, { silent = true, desc = "Close next fold level" })
    end,
  },
}
