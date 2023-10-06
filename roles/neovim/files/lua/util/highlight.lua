local M = {}

function M.bg(group, color)
  vim.cmd('hi ' .. group .. ' guibg=' .. color)
end

function M.fg(group, color)
  vim.cmd('hi ' .. group .. ' guifg=' .. color)
end

return M
