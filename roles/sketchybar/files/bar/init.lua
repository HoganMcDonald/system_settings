--- Example bar configuration using the sketchybar library
--- This demonstrates how to use the modular component system

local Bar = require('lib').Bar

local clock = require('bar.components.clock')
local wifi = require('bar.components.wifi')
local battery = require('bar.components.battery')
local mode_indicator = require('bar.components.mode_indicator')
local apple = require('bar.components.apple')

local M = {}

-- --- Example: System stats bracket
-- --- @return table Contains items and bracket
-- function M.create_system_stats()
--   -- Create individual items
--   local cpu = Item:new("item", "cpu", "right")
--   cpu:icon_string("󰻠")
--     :icon_color(0xff89b4fa)
--     :label_string("0%")
--     :label_color(0xffffffff)
--     :script("~/.config/sketchybar/plugins/cpu.sh", 5)
--
--   local memory = Item:new("item", "memory", "right")
--   memory:icon_string("󰍛")
--     :icon_color(0xfff38ba8)
--     :label_string("0%")
--     :label_color(0xffffffff)
--     :script("~/.config/sketchybar/plugins/memory.sh", 10)
--
--   -- Create bracket grouping the items
--   local bracket = Bracket:new("system_stats", {"cpu", "memory"})
--   bracket:bg_color(0xff1e1e2e)
--     :bg_corner_radius(5)
--     :bg_height(30)
--     :bg_border_width(1)
--     :bg_border_color(0xff313244)
--
--   return {
--     items = { cpu, memory },
--     bracket = bracket
--   }
-- end
--
-- --- Example: Custom event handler
-- --- @return Event
-- function M.create_custom_event()
--   local event = Event:new("my_custom_event")
--
--   event:subscribe(function(env)
--     print("Custom event triggered with data:", env.INFO)
--   end)
--
--   return event
-- end
--
-- --- Example: Animated item
-- --- @return table Contains item and animation
-- function M.create_animated_item()
--   local item = Item:new("item", "animated_item", "center")
--   item:icon_string("✨")
--     :icon_color(0xfff9e2af)
--     :bg_color(0xff1e1e2e)
--     :bg_corner_radius(15)
--     :bg_height(30)
--
--   local animation = Animation.bounce("bounce_anim", 0.5)
--
--   return {
--     item = item,
--     animation = animation
--   }
-- end

--- Initialize example components
function M.setup()
  -- Configure the bar
  local bar = Bar:new()
  bar:height(32)
    :blur_radius(30)
    :margin(20)
    :y_offset(15)
    :corner_radius(10)
    :position("top")
    :sticky(true)
    :padding(10, 10)
    :apply()

  -- Add custom events
  require('sbar').get().add("event", "aerospace_mode_change")

  -- Store references for later use
  M.components = {
    -- left
    apple = apple(),
    mode_indicator = mode_indicator(),

    -- right
    clock = clock(),
    wifi = wifi(),
    battery = battery(),
  }

  return M.components
end

return M
