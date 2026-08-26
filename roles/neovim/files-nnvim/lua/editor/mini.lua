local pack = require("lib.pack")

return {
  {
    src = pack.github("nvim-mini/mini.ai"),
    config = function()
      require("mini.ai").setup()
    end,
  },
  {
    src = pack.github("nvim-mini/mini.pairs"),
    config = function()
      require("mini.pairs").setup()
    end,
  },
}
