local pack = require("lib.pack")

return {
  src = pack.github("folke/todo-comments.nvim"),
  dependencies = pack.github("nvim-lua/plenary.nvim"),
  event = { "BufReadPost", "BufNewFile" },
  keys = {
    { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
    { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Search todo comments" },
  },
  config = function()
    require("todo-comments").setup()
  end,
}
