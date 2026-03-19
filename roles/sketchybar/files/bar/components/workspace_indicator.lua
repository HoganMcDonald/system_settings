local Bracket = require('lib').Bracket
local Item = require('lib').Item
local colors = require('colors')

local WORKSPACE_COUNT  = 4
local ACTIVE_WIDTH     = 24
local INACTIVE_WIDTH   = 12
local SPACER_WIDTH     = 6
local OVAL_HEIGHT      = 8
local OVAL_RADIUS      = 4

local function workspace_indicator()
  local workspace_items = {}
  local all_item_names = {}

  -- Create workspace oval indicators with spacers
  for i = 1, WORKSPACE_COUNT do
    local workspace_item = Item:new('item', 'workspace_' .. i, 'center')
    workspace_item:set {
      position = 'center',
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
    }

    table.insert(workspace_items, workspace_item)
    table.insert(all_item_names, 'workspace_' .. i)

    -- Add spacer between ovals (except after the last one)
    if i < WORKSPACE_COUNT then
      local spacer = Item:new('item', 'workspace_spacer_' .. i, 'center')
      spacer:set {
        position = 'center',
        icon = { drawing = false },
        label = { drawing = false },
        background = { drawing = false },
        width = SPACER_WIDTH,
        padding_left = 0,
        padding_right = 0,
      }
      table.insert(workspace_items, spacer)
      table.insert(all_item_names, 'workspace_spacer_' .. i)
    end
  end

  -- Create container bracket with all items (workspaces + spacers)
  local workspace_container = Bracket:new('workspaces', all_item_names)
  workspace_container:set {
    position = 'center',
  }

  -- Set up script for workspace detection
  workspace_items[1]:script('~/.config/sketchybar/plugins/workspace_indicator.sh', 1)
  workspace_items[1]:subscribe 'aerospace_workspace_change'

  -- Add all items to return table
  local return_items = {}
  for _, item in ipairs(workspace_items) do
    table.insert(return_items, item)
  end
  table.insert(return_items, workspace_container)

  return return_items
end

return workspace_indicator

