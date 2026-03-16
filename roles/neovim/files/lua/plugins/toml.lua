return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        taplo = {
          on_attach = function(client, bufnr)
            local uri = vim.uri_from_bufnr(bufnr)
            if uri and not uri:match("^file://") then
              vim.defer_fn(function()
                vim.lsp.buf_detach_client(bufnr, client.id)
              end, 0)
            end
          end,
        },
      },
    },
  },
}
