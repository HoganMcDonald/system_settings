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
--- @param curve? string Easing curve ("linear", "ease_in", "ease_out", "ease_in_out", "bounce", "overshoot")
--- @return Animation
function Animation:new(name, duration, curve)
  if not sbar then
    error("Animation not initialized. Call Animation.init(sbar) first.")
  end

  local instance = setmetatable({}, Animation)
  instance.name = name
  instance._duration = duration or 1.0
  instance._curve = curve or "ease_in_out"

  return instance
end

--- Start the animation, wrapping a callback where item :set() calls occur
--- @param callback function Function containing the property changes to animate
--- @return Animation
function Animation:start(callback)
  if not sbar then
    error("Animation not initialized. Call Animation.init(sbar) first.")
  end

  sbar.animate(self._curve, self._duration, callback or function() end)
  return self
end

--- Set animation duration
--- @param duration number Duration in seconds
--- @return Animation
function Animation:duration(duration)
  self._duration = duration
  return self
end

--- Set easing curve
--- @param curve string Easing curve name
--- @return Animation
function Animation:easing(curve)
  self._curve = curve
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
  return self._duration
end

--- Get animation easing curve
--- @return string Easing curve name
function Animation:get_easing()
  return self._curve
end

return Animation
