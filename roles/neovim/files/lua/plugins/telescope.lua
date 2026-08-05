return {
  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, opts)
      local actions = require("telescope.actions")

      opts.defaults = opts.defaults or {}
      opts.defaults.mappings = opts.defaults.mappings or {}

      for _, mode in ipairs({ "i", "n" }) do
        opts.defaults.mappings[mode] = opts.defaults.mappings[mode] or {}
        opts.defaults.mappings[mode]["<C-q>"] = function(prompt_bufnr)
          actions.send_to_qflist(prompt_bufnr)
          vim.cmd("Trouble qflist open")
        end
      end
    end,
  },
}
