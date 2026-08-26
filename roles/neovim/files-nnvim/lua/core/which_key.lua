local pack = require("lib.pack")

local groups = {
  { "<leader>a", group = "AI" },
  { "<leader><tab>", group = "Tabs" },
  { "<leader>b", group = "Buffers" },
  { "<leader>c", group = "Code" },
  { "<leader>f", group = "Files" },
  { "<leader>g", group = "Git" },
  { "<leader>m", group = "Marks" },
  { "<leader>n", group = "Notes" },
  { "<leader>q", group = "Quit / sessions" },
  { "<leader>s", group = "Search" },
  { "<leader>t", group = "Tests" },
  { "<leader>w", group = "Windows" },
  { "<leader>x", group = "Lists" },
}

return {
  src = pack.github("folke/which-key.nvim"),
  dependencies = pack.github("nvim-tree/nvim-web-devicons"),
  config = function()
    require("which-key").setup({
      spec = groups,
      preset = "modern",
      triggers = {},
    })

    vim.keymap.set({ "n", "x" }, "<leader>", function()
      require("which-key").show({ keys = "<leader>" })
    end, {
      desc = "WhichKey",
      nowait = true,
    })
  end,
}
