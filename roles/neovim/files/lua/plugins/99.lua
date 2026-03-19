return {
  {
    "ThePrimeagen/99",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>9s", function() require("99").search() end, desc = "99: Search" },
      { "<leader>9v", function() require("99").visual() end, mode = "v", desc = "99: Visual" },
      { "<leader>9x", function() require("99").stop_all_requests() end, desc = "99: Stop" },
      { "<leader>9o", function() require("99").open() end, desc = "99: Open last" },
      { "<leader>9m", function() require("99").select_model() end, desc = "99: Model" },
      { "<leader>9p", function() require("99").select_provider() end, desc = "99: Provider" },
    },
    opts = function()
      local _99 = require("99")
      return {
        provider = _99.Providers.ClaudeCodeProvider,
        completion = {
          source = "blink",
        },
      }
    end,
  },
}
