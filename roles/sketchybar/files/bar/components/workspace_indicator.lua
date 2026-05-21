local colors = require('colors')

local COUNT = 4
local ACTIVE_WIDTH = 24
local INACTIVE_WIDTH = 12
local SPACER_WIDTH = 6
local OVAL_HEIGHT = 8
local OVAL_RADIUS = 4

local items = {}

for i = 1, COUNT do
  local item = {
    name = 'workspace_' .. i,
    props = {
      icon = { drawing = false },
      label = { drawing = false },
      background = {
        drawing = true,
        color = colors.lavender,
        height = OVAL_HEIGHT,
        corner_radius = OVAL_RADIUS,
        padding_left = 0,
        padding_right = 0,
        y_offset = 0,
      },
      width = i == 1 and ACTIVE_WIDTH or INACTIVE_WIDTH,
      padding_left = 0,
      padding_right = 0,
    },
  }
  if i == 1 then
    item.script = 'workspace_indicator.sh'
    item.subscribe = { 'aerospace_workspace_change' }
  end
  table.insert(items, item)

  if i < COUNT then
    table.insert(items, {
      name = 'workspace_spacer_' .. i,
      props = {
        icon = { drawing = false },
        label = { drawing = false },
        background = { drawing = false },
        width = SPACER_WIDTH,
        padding_left = 0,
        padding_right = 0,
      },
    })
  end
end

---@type GroupSpec
return {
  group = { name = 'workspaces' },
  items = items,
}
