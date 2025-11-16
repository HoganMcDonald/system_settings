return {
  "dnlhc/glance.nvim",
  event = "LspAttach",
  config = function()
    require("glance").setup({
      height = 18,
      zindex = 45,
      preview_win_opts = {
        cursorline = true,
        number = true,
        wrap = true,
      },
      border = {
        enable = true,
        top_char = "─",
        bottom_char = "─",
      },
      list = {
        position = "right",
        width = 0.33,
      },
      theme = {
        enable = true,
        mode = "auto",
      },
      mappings = {
        list = {
          ["j"] = require("glance").actions.next,
          ["k"] = require("glance").actions.previous,
          ["<Down>"] = require("glance").actions.next,
          ["<Up>"] = require("glance").actions.previous,
          ["<Tab>"] = require("glance").actions.next_location,
          ["<S-Tab>"] = require("glance").actions.previous_location,
          ["<C-u>"] = require("glance").actions.preview_scroll_win(5),
          ["<C-d>"] = require("glance").actions.preview_scroll_win(-5),
          ["v"] = require("glance").actions.jump_vsplit,
          ["s"] = require("glance").actions.jump_split,
          ["t"] = require("glance").actions.jump_tab,
          ["<CR>"] = require("glance").actions.jump,
          ["o"] = require("glance").actions.jump,
          ["l"] = require("glance").actions.open_fold,
          ["h"] = require("glance").actions.close_fold,
          ["<leader>l"] = require("glance").actions.enter_win("preview"),
          ["q"] = require("glance").actions.close,
          ["Q"] = require("glance").actions.close,
          ["<Esc>"] = require("glance").actions.close,
        },
        preview = {
          ["Q"] = require("glance").actions.close,
          ["<Tab>"] = require("glance").actions.next_location,
          ["<S-Tab>"] = require("glance").actions.previous_location,
          ["<leader>l"] = require("glance").actions.enter_win("list"),
        },
      },
      hooks = {},
      folds = {
        fold_closed = "",
        fold_open = "",
        folded = true,
      },
      indent_lines = {
        enable = true,
        icon = "│",
      },
      winbar = {
        enable = true,
      },
    })

    -- Keybindings
    vim.keymap.set("n", "gD", "<CMD>Glance definitions<CR>", { desc = "Glance definitions" })
    vim.keymap.set("n", "gR", "<CMD>Glance references<CR>", { desc = "Glance references" })
    vim.keymap.set("n", "gY", "<CMD>Glance type_definitions<CR>", { desc = "Glance type definitions" })
    vim.keymap.set("n", "gI", "<CMD>Glance implementations<CR>", { desc = "Glance implementations" })
  end,
}
