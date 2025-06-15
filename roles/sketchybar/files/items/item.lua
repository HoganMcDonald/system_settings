---@class Item an item in sketchybar
---@field name string
---@field opts table
---@field render fun(self: Item)

local logger = require("helpers.logger")
local M = {}

---@param sbar SketchyBar
---@param name string
---@param props? table
---@return Item
function M:new(sbar, name, props)
  local instance = {}
  setmetatable(instance, {__index = self})
  instance.sbar = sbar
  instance.name = name or "item"
  instance.props = props or {}
  instance.item = nil

  logger.debug("Created new Item: " .. instance.name, "Item")
  return instance
end

function M:render()
  logger.info("Rendering Item: " .. self.name, "Item")
  self.item = self.sbar.add(
    "item",
    self.name,
    self.props
  )
  logger.debug("Item rendered successfully: " .. self.name, "Item")
  return self.item
end

return M
