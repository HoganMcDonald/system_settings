return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>e",
        "<cmd>Yazi<cr>",
        desc = "Open yazi at the current file",
      },
      {
        "<leader>E",
        "<cmd>Yazi cwd<cr>",
        desc = "Open yazi in working directory",
      },
    },
    opts = {
      -- Enable opening yazi for directories
      open_for_directories = false,
      keymaps = {
        show_help = "<f1>",
      },
      -- Match Telescope floating window style
      yazi_floating_window_winblend = 0,
      floating_window_scaling_factor = 0.9,
    },
    config = function(_, opts)
      require("yazi").setup(opts)

      -- Set solid background for yazi floating window (match Telescope)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "yazi",
        callback = function(ev)
          local win = vim.fn.bufwinid(ev.buf)
          if win ~= -1 then
            vim.api.nvim_set_option_value("winblend", 0, { win = win })
            vim.api.nvim_set_option_value(
              "winhighlight",
              "Normal:YaziFloat,FloatBorder:YaziBorder",
              { win = win }
            )
          end
        end,
      })
    end,
  },
}
