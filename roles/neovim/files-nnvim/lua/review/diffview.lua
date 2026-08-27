local pack = require("lib.pack")

---Diffview lives in its own tabpage, and both `get_current_view` and
---`:DiffviewClose` only ever consider the current one. Tracking every view
---instead is what stops a second `<leader>gg` from stacking another tab.
local function toggle()
  local lib = require("diffview.lib")

  -- Views whose tabpage was closed by hand linger in `lib.views`, and would
  -- otherwise count as open forever.
  lib.dispose_stray_views()

  local view = lib.views[1]

  if not view then
    vim.cmd.DiffviewOpen()
  elseif view.tabpage == vim.api.nvim_get_current_tabpage() then
    vim.cmd.DiffviewClose()
  else
    vim.api.nvim_set_current_tabpage(view.tabpage)
  end
end

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
    { "<leader>gg", toggle, desc = "Diffview" },
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
