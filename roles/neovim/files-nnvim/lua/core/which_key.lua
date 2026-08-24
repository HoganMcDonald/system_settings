local pack = require("lib.pack")

local groups = {
  { "<leader>a", group = "AI" },
  { "<leader><tab>", group = "Tabs" },
  { "<leader>b", group = "Buffers" },
  { "<leader>c", group = "Code" },
  { "<leader>f", group = "Files" },
  { "<leader>q", group = "Quit" },
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
    })
  end,
}
