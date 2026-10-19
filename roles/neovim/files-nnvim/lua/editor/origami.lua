local pack = require("lib.pack")

return {
  src = pack.github("chrisgrieser/nvim-origami"),
  event = "BufReadPost",
  config = function()
    require("origami").setup({
      pauseFoldsOnSearch = true,
      setupFoldKeymaps = true,
    })
  end,
}
