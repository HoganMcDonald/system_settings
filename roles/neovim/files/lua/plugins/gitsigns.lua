return {
  "lewis6991/gitsigns.nvim",
  keys = {
    { "<leader>gp", function() require("gitsigns").preview_hunk_inline() end, desc = "Preview Hunk Inline" },
    { "<leader>gP", function() require("gitsigns").preview_hunk() end, desc = "Preview Hunk (Float)" },
    { "<leader>hs", function() require("gitsigns").stage_hunk() end, desc = "Stage Hunk" },
    { "<leader>hr", function() require("gitsigns").reset_hunk() end, desc = "Reset Hunk" },
    { "<leader>hs", function() require("gitsigns").stage_hunk({vim.fn.line("."), vim.fn.line("v")}) end, mode = "v", desc = "Stage Hunk" },
    { "<leader>hr", function() require("gitsigns").reset_hunk({vim.fn.line("."), vim.fn.line("v")}) end, mode = "v", desc = "Reset Hunk" },
    { "]h", function() require("gitsigns").next_hunk() end, desc = "Next Hunk" },
    { "[h", function() require("gitsigns").prev_hunk() end, desc = "Prev Hunk" },
  },
}
