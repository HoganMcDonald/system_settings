local colors = require 'colors'

local COUNT = 4
local AEROSPACE = '/opt/homebrew/bin/aerospace'
local ACTIVE_COLOR = colors.with_alpha(colors.cyan, 0x2d)
local INACTIVE_COLOR = colors.panel_bg_dim

local items = {}

for i = 1, COUNT do
  table.insert(items, {
    name = 'workspace_' .. i,
    on_click = 'sh -c "' .. AEROSPACE .. ' workspace ' .. i .. '"',
    props = {
      icon = { string = tostring(i), color = i == 1 and colors.cyan or colors.subtext1, padding_left = 9, padding_right = 9 },
      label = { drawing = false },
      background = {
        drawing = true,
        color = i == 1 and ACTIVE_COLOR or INACTIVE_COLOR,
        border_width = 1,
        border_color = i == 1 and colors.cyan or colors.overlay2,
        height = 28,
        corner_radius = 3,
      },
      padding_left = 4,
      padding_right = 4,
    },
  })
end

---@type GroupSpec
return {
  group = {
    name = 'workspaces',
    props = { background = { drawing = false } },
  },
  items = items,
}
