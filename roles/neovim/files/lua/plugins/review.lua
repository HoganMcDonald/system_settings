return {
  {
    "vuki656/review.nvim",
    cmd = "Review",
    keys = {
      { "<leader>gR", "<cmd>Review<cr>", desc = "Review changes" },
      {
        "<leader>gq",
        function()
          require("review.quick_comments").add()
        end,
        desc = "Add review comment",
      },
      {
        "<leader>gq",
        function()
          require("review.quick_comments").add_visual()
        end,
        mode = "x",
        desc = "Add review comment",
      },
      {
        "<leader>gQ",
        function()
          require("review.quick_comments").toggle_panel()
        end,
        desc = "Review comments",
      },
    },
    opts = {
      ui = {
        diff_view_mode = "split",
      },
    },
  },
}
