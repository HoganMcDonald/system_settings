local M = {}

---@class SketchyBar
---@field begin_config fun()
---@field end_config fun()
---@field animate fun(animation: string, duration: number, callback: fun())
---@field event_loop fun()
---@field default fun(config: table)
---@field bar fun(config: table)
---@field add fun(type: string, name?: string, ...): any
---@field exec fun(command: string, ...): any

---@type SketchyBar
local sbar = require("sketchybar")

---Returns the SketchyBar instance.
---@return SketchyBar
M.get = function()
  return sbar
end

return M
