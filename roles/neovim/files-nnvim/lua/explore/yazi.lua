local pack = require("lib.pack")

return {
  src = pack.github("mikavilpas/yazi.nvim"),
  cmd = "Yazi",
  keys = {
    { "<leader>fe", "<cmd>Yazi<cr>", desc = "Yazi at current file" },
    { "<leader>fE", "<cmd>Yazi cwd<cr>", desc = "Yazi in working directory" },
  },
  config = function()
    require("yazi").setup({
      open_for_directories = false,
      keymaps = { show_help = "<F1>" },
      yazi_floating_window_winblend = 0,
      floating_window_scaling_factor = 0.9,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "yazi",
      callback = function(args)
        local win = vim.fn.bufwinid(args.buf)
        if win ~= -1 then
          vim.api.nvim_set_option_value("winblend", 0, { win = win })
          vim.api.nvim_set_option_value("winhighlight", "Normal:YaziFloat,FloatBorder:YaziBorder", { win = win })
        end
      end,
    })
  end,
}
