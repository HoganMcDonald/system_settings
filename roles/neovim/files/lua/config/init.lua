local M = {}

M.setup = function()
  require('config.options').setup()
  require('config.autocmds').setup()
  require('config.keymaps').setup()
end

return M
