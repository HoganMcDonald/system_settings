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
print("[sbar.lua] requiring sketchybar module...")
local ok, sbar = pcall(require, 'sketchybar')
if not ok then
  print('[sbar.lua] error:', sbar)
  sbar = nil
else
  print("[sbar.lua] sketchybar type:", type(sbar))
  if type(sbar) == "table" then
    for k, v in pairs(sbar) do
      print("[sbar.lua]  ", k, type(v))
    end
  else
    print("[sbar.lua] sketchybar value:", tostring(sbar))
  end
end

---Returns the SketchyBar instance.
---@return SketchyBar
M.get = function()
  return sbar
end

return M
