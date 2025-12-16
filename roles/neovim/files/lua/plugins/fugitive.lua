return {
  {
    "tpope/vim-fugitive",
    cmd = {
      "G",
      "Git",
      "Gdiffsplit",
      "Gread",
      "Gwrite",
      "Ggrep",
      "GMove",
      "GDelete",
      "GBrowse",
      "GRemove",
      "GRename",
      "Glgrep",
      "Gedit",
    },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
      { "<leader>gp", "<cmd>Git push<cr>", desc = "Git push" },
      { "<leader>gP", "<cmd>Git pull<cr>", desc = "Git pull" },
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
      { "<leader>gB", "<cmd>GBrowse<cr>", desc = "Git browse" },
      { "<leader>gw", "<cmd>Gwrite<cr>", desc = "Git write (stage current file)" },
      { "<leader>gr", "<cmd>Gread<cr>", desc = "Git read (checkout current file)" },
    },
  },
}
