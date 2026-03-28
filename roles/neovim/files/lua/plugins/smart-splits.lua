return {
  {
    "mrjones2014/smart-splits.nvim",
    version = ">=1.0.0",
    lazy = false,
    init = function()
      -- smart-splits' internal tmux navigation has a bug (exit code discarded,
      -- always returns false). Manage @pane-is-vim and edge navigation directly.
      if not vim.env.TMUX or not vim.env.TMUX_PANE then
        return
      end
      local pane = vim.env.TMUX_PANE
      local function set_flag(val)
        vim.fn.system({ "tmux", "set-option", "-pt", pane, "@pane-is-vim", val })
      end
      set_flag("1")
      vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
        callback = function()
          set_flag("0")
        end,
      })
      vim.api.nvim_create_autocmd("VimResume", {
        callback = function()
          set_flag("1")
        end,
      })
    end,
    opts = {
      default_amount = 3,
      -- at_edge: navigate to adjacent tmux pane, or stop if none exists
      at_edge = function(ctx)
        if not vim.env.TMUX then
          return
        end
        local dirs = { left = "L", right = "R", up = "U", down = "D" }
        local d = dirs[ctx.direction]
        if d then
          vim.fn.system({ "tmux", "select-pane", "-" .. d })
        end
      end,
      move_cursor_same_row = true,
      log_level = "fatal",
      -- disable built-in mux integration; @pane-is-vim is managed in init above
      multiplexer_integration = false,
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
