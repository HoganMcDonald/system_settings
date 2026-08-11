local M = {}

---@param servers? table<string, vim.lsp.Config>
function M.setup(servers)
  vim.diagnostic.config({
    severity_sort = true,
    underline = true,
    virtual_text = true,
  })

  for name, config in pairs(servers or {}) do
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
  end
end

return M
