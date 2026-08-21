local M = {}

---@param servers? table<string, vim.lsp.Config>
function M.setup(servers)
  vim.diagnostic.config({
    severity_sort = true,
    underline = true,
    virtual_text = true,
    virtual_lines = { current_line = true },
    update_in_insert = false,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("Nvim_lsp_attach", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local uri = vim.uri_from_bufnr(args.buf)

      if uri and not uri:match("^file://") then
        if client then
          vim.schedule(function()
            vim.lsp.buf_detach_client(args.buf, client.id)
          end)
        end
        return
      end

      vim.keymap.set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, {
        buffer = args.buf,
        desc = "Code action",
      })
    end,
  })

  local virtual_text
  vim.api.nvim_create_autocmd({ "CursorMoved", "DiagnosticChanged" }, {
    group = vim.api.nvim_create_augroup("Nvim_diagnostic_display", { clear = true }),
    callback = function()
      if vim.tbl_isempty(vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })) then
        if virtual_text ~= nil then
          vim.diagnostic.config({ virtual_text = virtual_text })
          virtual_text = nil
        end
      else
        virtual_text = virtual_text or vim.diagnostic.config().virtual_text
        vim.diagnostic.config({ virtual_text = false })
      end
    end,
  })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = vim.api.nvim_create_augroup("Nvim_diagnostic_redraw", { clear = true }),
    callback = function()
      pcall(vim.diagnostic.show)
    end,
  })

  for name, config in pairs(servers or {}) do
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
  end
end

return M
