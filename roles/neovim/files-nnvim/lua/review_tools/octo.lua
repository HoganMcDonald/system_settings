local pack = require("lib.pack")

return {
  src = pack.github("pwntester/octo.nvim"),
  dependencies = {
    pack.github("nvim-lua/plenary.nvim"),
    pack.github("folke/snacks.nvim"),
    pack.github("nvim-tree/nvim-web-devicons"),
  },
  cmd = "Octo",
  keys = {
    { "<leader>gof", "<cmd>Octo search is:pr is:open author:@me review:changes_requested<cr>", desc = "PRs needing fixes" },
    { "<leader>gol", "<cmd>Octo pr list<cr>", desc = "Pull requests" },
    { "<leader>gop", "<cmd>Octo pr<cr>", desc = "Current pull request" },
    { "<leader>gor", "<cmd>Octo review browse<cr>", desc = "Browse PR review" },
  },
  config = function()
    require("octo").setup({
      picker = "snacks",
      enable_builtin = true,
      use_local_fs = true,
      reviews = {
        auto_show_threads = true,
        show_virtual_text = true,
      },
    })
  end,
}
