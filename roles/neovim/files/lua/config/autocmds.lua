-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Detach LSP clients from non-file buffers (e.g. diffview://) to prevent crashes
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("detach_lsp_from_non_file", { clear = true }),
  callback = function(args)
    local uri = vim.uri_from_bufnr(args.buf)
    if uri and not uri:match("^file://") then
      vim.defer_fn(function()
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
          vim.lsp.buf_detach_client(args.buf, client.id)
        end
      end, 0)
    end
  end,
})
