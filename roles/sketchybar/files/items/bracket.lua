---@class Bracket a bracket in sketchybar
---@field name string
---@field opts table
---@field render fun(self: Bracket)

local logger = require("helpers.logger")
local M = {}

---@param sbar SketchyBar
---@param name string
---@param mems? table<string>
---@param props? table
---@return Bracket
function M:new(sbar, name, mems, props)
  local instance = {}
  setmetatable(instance, {__index = self})
  instance.sbar = sbar
  instance.name = name or "bracket"
  instance.mems = mems or {}
  instance.props = props or {}

  logger.debug("Created new Bracket: " .. instance.name .. " with " .. #instance.mems .. " members", "Bracket")
  return instance
end

function M:render()
  logger.info("Rendering Bracket: " .. self.name .. " with members: " .. table.concat(self.mems, ", "), "Bracket")
  self.sbar.add(
    "bracket",
    self.name,
    self.mems,
    self.props
  )
  logger.debug("Bracket rendered successfully: " .. self.name, "Bracket")
end

return M
