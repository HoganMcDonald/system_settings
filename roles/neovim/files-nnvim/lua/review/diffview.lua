local pack = require("lib.pack")

return {
  src = pack.github("sindrets/diffview.nvim"),
  dependencies = pack.github("nvim-lua/plenary.nvim"),
  cmd = {
    "DiffviewClose",
    "DiffviewFileHistory",
    "DiffviewFocusFiles",
    "DiffviewOpen",
    "DiffviewRefresh",
    "DiffviewToggleFiles",
  },
  keys = {
    { "<leader>gg", "<cmd>DiffviewOpen<cr>", desc = "Open diffview" },
    {
      "<leader>gv",
      function()
        if require("diffview.lib").get_current_view() then
          vim.cmd("DiffviewClose")
        else
          vim.cmd("DiffviewOpen")
        end
      end,
      desc = "Diffview",
    },
    { "<leader>gV", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview file history" },
  },
  config = function()
    require("diffview").setup({
      enhanced_diff_hl = true,
      view = { merge_tool = { layout = "diff3_mixed" } },
      file_panel = {
        listing_style = "tree",
        win_config = {
          position = "left",
          width = 35,
        },
      },
    })
  end,
}
