--- Event class for SketchyBar events
--- Handles creation and management of custom events
--- @class Event

local Event = {}
Event.__index = Event

--- @type table SbarLua instance
local sbar = nil

--- Initialize the Event class with SbarLua instance  
--- @param sbar_instance table The SbarLua instance
function Event.init(sbar_instance)
  sbar = sbar_instance
end

--- Create a new Event instance
--- @param name string Event name/identifier
--- @return Event
function Event:new(name)
  if not sbar then
    error("Event not initialized. Call Event.init(sbar) first.")
  end
  
  local instance = setmetatable({}, Event)
  instance.name = name
  instance.subscribers = {}
  
  -- Create the event in sketchybar
  instance.sbar_event = sbar.add("event", instance.name)
  
  return instance
end

--- Trigger/fire the event
--- @param data? table Optional data to pass with the event
--- @return Event
function Event:trigger(data)
  if not self.sbar_event then
    error("Event not properly initialized")
  end
  
  if data then
    self.sbar_event:trigger(data)
  else
    self.sbar_event:trigger()
  end
  
  return self
end

--- Subscribe a callback to this event
--- @param callback function Callback function to execute when event is triggered
--- @return Event
function Event:subscribe(callback)
  if not self.sbar_event then
    error("Event not properly initialized")
  end
  
  table.insert(self.subscribers, callback)
  self.sbar_event:subscribe(self.name, callback)
  
  return self
end

--- Get event name
--- @return string Event name
function Event:get_name()
  return self.name
end

--- Get list of subscribers
--- @return function[] List of callback functions
function Event:get_subscribers()
  local subscribers_copy = {}
  for i, subscriber in ipairs(self.subscribers) do
    subscribers_copy[i] = subscriber
  end
  return subscribers_copy
end

--- Remove/delete the event
function Event:remove()
  if self.sbar_event and self.sbar_event.remove then
    self.sbar_event:remove()
  end
  self.sbar_event = nil
  self.subscribers = {}
end

return Event