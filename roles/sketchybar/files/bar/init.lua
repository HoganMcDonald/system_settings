--- Example bar configuration using the sketchybar library
--- This demonstrates how to use the modular component system

local sbar = require('sbar').get()
local lib = require('lib').init(sbar)

local M = {}

--- Example: Simple clock component
--- @return Item
function M.create_clock()
  local clock = lib.Item:new("item", "clock", "right")
  
  clock:label_string(os.date("%H:%M"))
    :label_color(0xffffffff)
    :label_font("SF Pro Display", 14)
    :bg_color(0xff1e1e2e)
    :bg_corner_radius(5)
    :bg_height(30)
    :bg_border_width(1)
    :bg_border_color(0xff313244)
    :padding(10, 10)
    :script("~/.config/sketchybar/plugins/clock.sh", 30)
  
  return clock
end

--- Example: System stats bracket
--- @return table Contains items and bracket
function M.create_system_stats()
  -- Create individual items
  local cpu = lib.Item:new("item", "cpu", "right")
  cpu:icon_string("󰻠")
    :icon_color(0xff89b4fa)
    :label_string("0%")
    :label_color(0xffffffff)
    :script("~/.config/sketchybar/plugins/cpu.sh", 5)
  
  local memory = lib.Item:new("item", "memory", "right")
  memory:icon_string("󰍛")
    :icon_color(0xfff38ba8)
    :label_string("0%")
    :label_color(0xffffffff)
    :script("~/.config/sketchybar/plugins/memory.sh", 10)
  
  -- Create bracket grouping the items
  local bracket = lib.Bracket:new("system_stats", {"cpu", "memory"})
  bracket:bg_color(0xff1e1e2e)
    :bg_corner_radius(5)
    :bg_height(30)
    :bg_border_width(1)
    :bg_border_color(0xff313244)
  
  return {
    items = { cpu, memory },
    bracket = bracket
  }
end

--- Example: Custom event handler
--- @return Event
function M.create_custom_event()
  local event = lib.Event:new("my_custom_event")
  
  event:subscribe(function(env)
    print("Custom event triggered with data:", env.INFO)
  end)
  
  return event
end

--- Example: Animated item
--- @return table Contains item and animation
function M.create_animated_item()
  local item = lib.Item:new("item", "animated_item", "center")
  item:icon_string("✨")
    :icon_color(0xfff9e2af)
    :bg_color(0xff1e1e2e)
    :bg_corner_radius(15)
    :bg_height(30)
  
  local animation = lib.Animation.bounce("bounce_anim", 0.5)
  
  return {
    item = item,
    animation = animation
  }
end

--- Initialize example components
function M.setup()
  -- Configure the bar
  local bar = lib.Bar:new()
  bar:height(32)
    :color(0xff1e1e2e)
    :border_color(0xff313244)
    :border_width(1)
    :corner_radius(5)
    :position("top")
    :sticky(true)
    :padding(10, 10)
    :apply()
  
  -- Create example components
  local clock = M.create_clock()
  local system_stats = M.create_system_stats()
  local custom_event = M.create_custom_event()
  local animated_item = M.create_animated_item()
  
  -- Store references for later use
  M.components = {
    clock = clock,
    system_stats = system_stats,
    custom_event = custom_event,
    animated_item = animated_item
  }
  
  return M.components
end

return M