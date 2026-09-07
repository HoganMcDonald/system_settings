local pack = require("lib.pack")

return {
  src = pack.github("fnune/recall.nvim"),
  -- A VersionRange tracks the latest semver tag; the "*" string is treated
  -- as a literal ref by vim.pack and fails to resolve on (re)install.
  version = vim.version.range("*"),
  keys = {
    { "<leader>mm", function() require("recall").toggle() end, desc = "Toggle mark" },
    { "<leader>mn", function() require("recall").goto_next() end, desc = "Next mark" },
    { "<leader>mp", function() require("recall").goto_prev() end, desc = "Previous mark" },
    { "<leader>mc", function() require("recall").clear() end, desc = "Clear marks" },
    { "<leader>mo", function() require("recall.snacks").pick() end, desc = "Open marks" },
    { "<Tab>", function() require("recall").goto_next() end, desc = "Next mark" },
    { "<S-Tab>", function() require("recall").goto_prev() end, desc = "Previous mark" },
  },
  config = function()
    vim.api.nvim_set_hl(0, "RecallSign", { default = true, link = "@comment.note" })
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.api.nvim_set_hl(0, "RecallSign", { default = true, link = "@comment.note" })
      end,
    })

    require("recall").setup({
      sign = "",
      sign_highlight = "RecallSign",
      snacks = {
        mappings = {
          unmark_selected_entry = { normal = "dd", insert = "<M-d>" },
        },
      },
    })
  end,
}
