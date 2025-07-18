--- SketchyBar Component Library
--- A modular component system built on top of SbarLua
--- @module sketchybar-lib

local M = {}

M.Bar = require('lib.bar')
M.Item = require('lib.item')
M.Bracket = require('lib.bracket')
M.Event = require('lib.event')
M.Animation = require('lib.animation')

--- Initialize the library with SbarLua instance
--- @param sbar table The SbarLua instance
--- @return table The initialized library
function M.init(sbar)
  M.sbar = sbar
  M.Bar.init(sbar)
  M.Item.init(sbar)
  M.Bracket.init(sbar)
  M.Event.init(sbar)
  M.Animation.init(sbar)
  return M
end

return M
