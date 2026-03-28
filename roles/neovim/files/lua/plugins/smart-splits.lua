return {
  {
    "mrjones2014/smart-splits.nvim",
    version = ">=1.0.0",
    -- must load eagerly so @pane-is-vim is set in tmux before any keypress
    lazy = false,
    opts = {
      default_amount = 3,
      -- stop at edge; multiplexer integration handles crossing into tmux panes
      at_edge = "stop",
      move_cursor_same_row = true,
      log_level = "fatal",
      multiplexer_integration = "tmux",
    },
    keys = {
      -- Resize: option+= to grow right, option+- to shrink left
      {
        "<A-=>",
        function()
          require("smart-splits").resize_right()
        end,
        desc = "Resize split right",
      },
      {
        "<A-->",
        function()
          require("smart-splits").resize_left()
        end,
        desc = "Resize split left",
      },

      -- Navigation: Ctrl+hjkl, bridges into adjacent tmux panes at edge
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
