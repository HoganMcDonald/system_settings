return {
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
    },
    -- Keybindings defined in lua/config/keymaps.lua
    opts = {
      enhanced_diff_hl = true,
      use_icons = true,
      view = {
        default = {
          layout = "diff2_horizontal",
        },
      },
      file_panel = {
        listing_style = "tree",
        tree_options = {
          flatten_dirs = true,
        },
        win_config = {
          position = "left",
          width = 35,
        },
      },
    },
  },
}
