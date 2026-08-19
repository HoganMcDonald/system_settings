local pack = require("lib.pack")

return {
  src = pack.github("nvim-neo-tree/neo-tree.nvim"),
  dependencies = {
    pack.github("nvim-lua/plenary.nvim"),
    pack.github("MunifTanjim/nui.nvim"),
    pack.github("nvim-tree/nvim-web-devicons"),
  },
  cmd = "Neotree",
  config = function()
    require("neo-tree").setup({
      sources = { "filesystem", "buffers", "git_status" },
      close_if_last_window = false,
      open_files_do_not_replace_types = { "edgy", "Outline", "terminal", "qf" },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
      window = { width = 40 },
    })
  end,
}
