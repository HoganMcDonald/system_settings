local M = {}

---Whether a window showing `filetype` is open in the current tab.
---@param filetype string
---@return boolean
function M.has_filetype(filetype)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == filetype then
      return true
    end
  end

  return false
end

---Close an Edgy-managed window by filetype in the current tab.
---@param filetype string
function M.close_filetype(filetype)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == filetype then
      local edgy_win = require("edgy").get_win(win)
      if edgy_win then
        edgy_win:close()
      end
    end
  end
end

return M
