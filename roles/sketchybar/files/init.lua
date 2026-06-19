local M = {}

print("[init.lua] loading sbar...")
M.sbar = require('sbar').get()
print("[init.lua] sbar type:", type(M.sbar))
print("[init.lua] requiring bar...")
local bar = require 'bar'
print("[init.lua] initializing lib...")
local lib = require('lib').init(M.sbar)

M.setup = function()
  print("[init.lua] begin_config...")
  M.sbar.begin_config()

  print("[init.lua] bar.setup()...")
  bar.setup()

  print("[init.lua] end_config...")
  M.sbar.end_config()

  print("[init.lua] event_loop...")
  M.sbar.event_loop()
end

print("[init.lua] calling setup...")
M.setup()
print("[init.lua] setup done")

return M
