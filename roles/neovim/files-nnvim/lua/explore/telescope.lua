local pack = require("lib.pack")

return {
  src = pack.github("nvim-telescope/telescope.nvim"),
  dependencies = pack.github("nvim-lua/plenary.nvim"),
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep files" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Find diagnostics" },
  },
  config = function()
    require("telescope").setup({
      defaults = {
        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },
        file_ignore_patterns = { "%.git/", "node_modules/" },
      },
      pickers = {
        find_files = { hidden = true },
      },
    })
  end,
}
