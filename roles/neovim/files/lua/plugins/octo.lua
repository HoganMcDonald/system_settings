return {
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
      "nvim-mini/mini.icons",
    },
    opts = {
      picker = "snacks",
      enable_builtin = true,
      use_local_fs = true,
      file_panel = {
        icons = function(name, _ext)
          return require("mini.icons").get("file", name)
        end,
      },
    },
    keys = {
      { "<leader>oo", "<cmd>Octo<cr>", desc = "Octo" },
      { "<leader>oi", "<cmd>Octo issue list<cr>", desc = "List GitHub Issues" },
      { "<leader>op", "<cmd>Octo pr list<cr>", desc = "List GitHub Pull Requests" },
      { "<leader>or", "<cmd>Octo repo view<cr>", desc = "View GitHub Repo" },
      { "<leader>on", "<cmd>Octo notification list<cr>", desc = "List GitHub Notifications" },
      {
        "<leader>os",
        function()
          require("octo.utils").create_base_search_command({ include_current_repo = true })
        end,
        desc = "Search GitHub",
      },
    },
  },
}
