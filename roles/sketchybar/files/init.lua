local M = {}

M.sbar = require('sbar').get()
local lib = require('lib').init(M.sbar)
local bar = require('bar')

M.setup = function()
  M.sbar.begin_config()

  bar.setup()

  M.sbar.end_config()

  M.sbar.event_loop()
end

M.setup()

return M
