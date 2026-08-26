local pack = require("lib.pack")

return {
  src = pack.github("folke/ts-comments.nvim"),
  config = function()
    require("ts-comments").setup()
  end,
}
