return {
  {
    "mrjones2014/smart-splits.nvim",
    version = ">=1.0.0",
    build = "./kitty/install-kittens.bash",
    opts = {
      -- Default amount of lines/columns to resize by
      default_amount = 3,
      -- Behavior at edge: 'wrap' | 'split' | 'stop'
      at_edge = "wrap",
      -- Move cursor to same row regardless of line numbers
      move_cursor_same_row = true,
      -- Disable logging to prevent error messages
      log_level = "off",
    },
    keys = {
      -- Smart resize: resizes in the direction you specify
      -- Vertical splits resize horizontally, horizontal splits resize vertically
      -- Using Ctrl+Arrow keys to avoid Alt key delay on macOS
      {
        "<A-h>",
        function()
          require("smart-splits").resize_left()
        end,
        desc = "Resize split left",
      },
      {
        "<A-j>",
        function()
          require("smart-splits").resize_down()
        end,
        desc = "Resize split down",
      },
      {
        "<A-k>",
        function()
          require("smart-splits").resize_up()
        end,
        desc = "Resize split up",
      },
      {
        "<A-l>",
        function()
          require("smart-splits").resize_right()
        end,
        desc = "Resize split right",
      },

      -- Smart navigation between splits (integrates with Kitty/Zellij/Tmux)
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
        desc = "Move to left split",
      },
      {
        "<C-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
        desc = "Move to split below",
      },
      {
        "<C-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
        desc = "Move to split above",
      },
      {
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
        desc = "Move to right split",
      },

      -- Swapping buffers between windows
      {
        "<leader>wh",
        function()
          require("smart-splits").swap_buf_left()
        end,
        desc = "Swap buffer left",
      },
      {
        "<leader>wj",
        function()
          require("smart-splits").swap_buf_down()
        end,
        desc = "Swap buffer down",
      },
      {
        "<leader>wk",
        function()
          require("smart-splits").swap_buf_up()
        end,
        desc = "Swap buffer up",
      },
      {
        "<leader>wl",
        function()
          require("smart-splits").swap_buf_right()
        end,
        desc = "Swap buffer right",
      },
    },
  },
}
