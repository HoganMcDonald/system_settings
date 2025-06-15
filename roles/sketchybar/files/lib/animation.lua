--- Animation class for SketchyBar animations
--- Handles creation and management of animations
--- @class Animation

local Animation = {}
Animation.__index = Animation

--- @type table SbarLua instance
local sbar = nil

--- Initialize the Animation class with SbarLua instance
--- @param sbar_instance table The SbarLua instance
function Animation.init(sbar_instance)
  sbar = sbar_instance
end

--- Create a new Animation instance
--- @param name string Animation name/identifier
--- @param duration number Animation duration in seconds
--- @param easing? string Easing function ("linear", "ease_in", "ease_out", "ease_in_out", "bounce", "overshoot", "cubic_bezier")
--- @return Animation
function Animation:new(name, duration, easing)
  if not sbar then
    error("Animation not initialized. Call Animation.init(sbar) first.")
  end
  
  local instance = setmetatable({}, Animation)
  instance.name = name
  instance.duration = duration or 1.0
  instance.easing = easing or "ease_in_out"
  instance.properties = {}
  
  return instance
end

--- Set animation properties
--- @param properties table Properties to animate
--- @return Animation
function Animation:set_properties(properties)
  for k, v in pairs(properties) do
    self.properties[k] = v
  end
  return self
end

--- Start the animation
--- @param callback? function Optional callback to execute when animation completes
--- @return Animation
function Animation:start(callback)
  if not sbar then
    error("Animation not initialized. Call Animation.init(sbar) first.")
  end
  
  local animation_config = {
    duration = self.duration,
    curve = self.easing
  }
  
  if callback then
    sbar.animate(animation_config, function()
      callback()
    end)
  else
    sbar.animate(animation_config)
  end
  
  return self
end

--- Set animation duration
--- @param duration number Duration in seconds
--- @return Animation
function Animation:duration(duration)
  self.duration = duration
  return self
end

--- Set easing function
--- @param easing string Easing function name
--- @return Animation
function Animation:easing(easing)
  self.easing = easing
  return self
end

--- Create a linear animation
--- @param name string Animation name
--- @param duration number Duration in seconds
--- @return Animation
function Animation.linear(name, duration)
  return Animation:new(name, duration, "linear")
end

--- Create an ease-in animation
--- @param name string Animation name
--- @param duration number Duration in seconds
--- @return Animation
function Animation.ease_in(name, duration)
  return Animation:new(name, duration, "ease_in")
end

--- Create an ease-out animation
--- @param name string Animation name
--- @param duration number Duration in seconds
--- @return Animation
function Animation.ease_out(name, duration)
  return Animation:new(name, duration, "ease_out")
end

--- Create an ease-in-out animation
--- @param name string Animation name
--- @param duration number Duration in seconds
--- @return Animation
function Animation.ease_in_out(name, duration)
  return Animation:new(name, duration, "ease_in_out")
end

--- Create a bounce animation
--- @param name string Animation name
--- @param duration number Duration in seconds
--- @return Animation
function Animation.bounce(name, duration)
  return Animation:new(name, duration, "bounce")
end

--- Create an overshoot animation
--- @param name string Animation name
--- @param duration number Duration in seconds
--- @return Animation
function Animation.overshoot(name, duration)
  return Animation:new(name, duration, "overshoot")
end

--- Get animation name
--- @return string Animation name
function Animation:get_name()
  return self.name
end

--- Get animation duration
--- @return number Duration in seconds
function Animation:get_duration()
  return self.duration
end

--- Get animation easing
--- @return string Easing function name
function Animation:get_easing()
  return self.easing
end

--- Get animation properties
--- @return table Animation properties
function Animation:get_properties()
  local properties_copy = {}
  for k, v in pairs(self.properties) do
    if type(v) == "table" then
      properties_copy[k] = {}
      for k2, v2 in pairs(v) do
        properties_copy[k][k2] = v2
      end
    else
      properties_copy[k] = v
    end
  end
  return properties_copy
end

return Animation