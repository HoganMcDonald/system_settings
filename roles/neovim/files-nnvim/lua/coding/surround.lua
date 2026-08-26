local pack = require("lib.pack")

return {
  src = pack.github("kylechui/nvim-surround"),
  version = "*",
  event = "BufReadPost",
  config = function()
    require("nvim-surround").setup({})
  end,
}
