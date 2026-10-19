local pack = require("lib.pack")

return {
  src = pack.github("anuvyklack/pretty-fold.nvim"),
  event = "BufReadPost",
  config = function()
    require("pretty-fold").setup({
      fill_char = "-",
      sections = {
        left = { "content" },
        right = { " " },
      },
    })
  end,
}
