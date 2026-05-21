--- SketchyBar library: declarative renderer + helpers.

local M = {}

M.Event = require('lib.event')
M.render = require('lib.render')

function M.init(sbar)
  M.sbar = sbar
  M.Event.init(sbar)
  M.render.init(sbar)
  return M
end

return M
