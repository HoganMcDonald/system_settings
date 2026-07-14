return {
  {
    "mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "tsgo") then
        table.insert(opts.ensure_installed, "tsgo")
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local configs = require("lspconfig.configs")
      local util = require("lspconfig.util")

      if not configs.tsgo then
        configs.tsgo = {
          default_config = {
            cmd = { "tsgo", "--lsp", "--stdio" },
            filetypes = {
              "javascript",
              "javascriptreact",
              "typescript",
              "typescriptreact",
            },
            root_dir = util.root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git"),
            single_file_support = true,
          },
        }
      end

      opts.servers = opts.servers or {}
      opts.servers.vtsls = { enabled = false }
      opts.servers.tsgo = {}
    end,
  },
}
