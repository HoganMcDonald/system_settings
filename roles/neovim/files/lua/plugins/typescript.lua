return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          settings = {
            typescript = {
              tsserver = {
                maxTsServerMemory = 8192, -- Set to 8GB (adjust as needed)
              },
            },
            javascript = {
              tsserver = {
                maxTsServerMemory = 8192, -- Set to 8GB (adjust as needed)
              },
            },
          },
        },
      },
    },
  },
}
