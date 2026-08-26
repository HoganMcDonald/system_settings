local pack = require("lib.pack")

return {
  src = pack.github("folke/flash.nvim"),
  keys = {
    { "f", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash" },
    { "F", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash Treesitter" },
    { "r", function() require("flash").remote() end, mode = "o", desc = "Remote Flash" },
    { "R", function() require("flash").treesitter_search() end, mode = { "o", "x" }, desc = "Treesitter search" },
    { "<C-s>", function() require("flash").toggle() end, mode = "c", desc = "Toggle Flash search" },
  },
  config = function()
    require("flash").setup({ modes = { char = { enabled = false } } })
  end,
}
