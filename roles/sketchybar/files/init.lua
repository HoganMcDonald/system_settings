local M = {}

M.sbar = require('sbar').get()

M.setup = function()
  M.sbar.begin_config()

  ---TODO: Load your bar configuration here

  M.sbar.end_config()

  M.sbar.event_loop()
end

M.setup()

return M
