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
      mappings = {
        pull_request = {
          review_start = { lhs = "<leader>ovs", desc = "start review" },
          review_resume = { lhs = "<leader>ovr", desc = "resume review" },
          list_changed_files = { lhs = "<leader>opf", desc = "list PR changed files" },
          show_pr_diff = { lhs = "<leader>opd", desc = "show PR diff" },
        },
        review_thread = {
          add_comment = { lhs = "<leader>oca", desc = "add comment" },
          add_reply = { lhs = "<leader>ocr", desc = "add reply" },
          add_suggestion = { lhs = "<leader>osa", desc = "add suggestion" },
          resolve_thread = { lhs = "<leader>ort", desc = "resolve thread" },
          unresolve_thread = { lhs = "<leader>orT", desc = "unresolve thread" },
        },
        review_diff = {
          submit_review = { lhs = "<leader>ovs", desc = "submit review" },
          discard_review = { lhs = "<leader>ovd", desc = "discard review" },
          add_review_comment = {
            lhs = "<leader>oca",
            desc = "add review comment",
            mode = { "n", "x" },
          },
          add_review_suggestion = {
            lhs = "<leader>osa",
            desc = "add review suggestion",
            mode = { "n", "x" },
          },
          focus_files = { lhs = "<leader>oe", desc = "focus changed files" },
          toggle_files = { lhs = "<leader>ob", desc = "toggle changed files" },
        },
        file_panel = {
          submit_review = { lhs = "<leader>ovs", desc = "submit review" },
          discard_review = { lhs = "<leader>ovd", desc = "discard review" },
          focus_files = { lhs = "<leader>oe", desc = "focus changed files" },
          toggle_files = { lhs = "<leader>ob", desc = "toggle changed files" },
        },
        submit_win = {
          approve_review = { lhs = "<leader>ova", desc = "approve review", mode = { "n" } },
          comment_review = { lhs = "<leader>ovc", desc = "comment review", mode = { "n" } },
          request_changes = { lhs = "<leader>ovr", desc = "request changes", mode = { "n" } },
        },
      },
      file_panel = {
        icons = function(name, _ext)
          return require("mini.icons").get("file", name)
        end,
      },
    },
    keys = {
      { "<leader>oo", "<cmd>Octo<cr>", desc = "Octo" },
      { "<leader>op", "<cmd>Octo pr list<cr>", desc = "List GitHub Pull Requests" },
      {
        "<leader>or",
        "<cmd>Octo search is:pr is:open review-requested:@me archived:false<cr>",
        desc = "List Pull Requests Awaiting My Review",
      },
      {
        "<leader>om",
        "<cmd>Octo search is:pr is:open author:@me archived:false<cr>",
        desc = "List My Open Pull Requests",
      },
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
