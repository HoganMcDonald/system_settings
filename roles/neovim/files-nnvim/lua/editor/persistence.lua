local pack = require("lib.pack")

return {
  src = pack.github("folke/persistence.nvim"),
  event = "BufReadPre",
  cmd = "PersistenceLoadLast",
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore session" },
    { "<leader>qS", function() require("persistence").select() end, desc = "Select session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't save session" },
  },
  config = function()
    require("persistence").setup()
    vim.api.nvim_create_user_command("PersistenceLoadLast", function()
      require("persistence").load({ last = true })
    end, { desc = "Restore the previous session" })
  end,
}
