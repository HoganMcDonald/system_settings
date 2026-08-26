local pack = require("lib.pack")

return {
  src = pack.github("MagicDuck/grug-far.nvim"),
  cmd = { "GrugFar", "GrugFarWithin" },
  keys = {
    { "<leader>sr", "<cmd>GrugFar<cr>", mode = { "n", "x" }, desc = "Search and replace" },
  },
  config = function()
    require("grug-far").setup({})
  end,
}
