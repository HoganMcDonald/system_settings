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
    -- The git status source asks git to enumerate ignored files, which walks
    -- every ignored path -- seconds of blocking work in a repo with a large
    -- node_modules tree. The filesystem source needs that information to honour
    -- `hide_gitignored`, so the override is scoped to this source alone.
    local items = require("neo-tree.sources.git_status.lib.items")
    local get_git_status = items.get_git_status

    items.get_git_status = function(state)
      local git = require("neo-tree.git")
      local status = git.status

      git.status = function(path, base, exclude_directories, opts)
        opts = vim.tbl_extend("force", opts or {}, { ignored = "no" })
        return status(path, base, exclude_directories, opts)
      end

      local ok, err = pcall(get_git_status, state)
      git.status = status

      if not ok then
        error(err)
      end
    end

    require("neo-tree").setup({
      sources = { "filesystem", "buffers", "git_status" },
      close_if_last_window = false,
      open_files_do_not_replace_types = { "edgy", "Outline", "terminal", "qf" },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        -- Watching every directory is expensive on large trees; writes still
        -- refresh the tree via `enable_refresh_on_write`.
        use_libuv_file_watcher = false,
      },
      window = {
        width = 40,
        mappings = { l = "open" },
      },
    })
  end,
}
