--- Bar class for SketchyBar configuration
--- Handles global bar properties and configuration
--- @class Bar

local Bar = {}
Bar.__index = Bar

--- @type table SbarLua instance
local sbar = nil

--- Initialize the Bar class with SbarLua instance
--- @param sbar_instance table The SbarLua instance
function Bar.init(sbar_instance)
  sbar = sbar_instance
end

--- Create a new Bar instance
--- @param config? table Initial bar configuration
--- @return Bar
function Bar:new(config)
  local instance = setmetatable({}, Bar)
  instance.config = config or {}
  return instance
end

--- Configure the bar with properties
--- @param config table Bar configuration properties
--- @return Bar
function Bar:configure(config)
  if not sbar then
    error("Bar not initialized. Call Bar.init(sbar) first.")
  end
  
  for k, v in pairs(config) do
    self.config[k] = v
  end
  sbar.bar(self.config)
  return self
end

--- Set bar height
--- @param height number Height in pixels
--- @return Bar
function Bar:height(height)
  return self:configure({ height = height })
end

--- Set bar color
--- @param color number|string Color value (hex or integer)
--- @return Bar
function Bar:color(color)
  return self:configure({ color = color })
end

--- Set bar border color
--- @param color number|string Border color value
--- @return Bar
function Bar:border_color(color)
  return self:configure({ border_color = color })
end

--- Set bar border width
--- @param width number Border width in pixels
--- @return Bar
function Bar:border_width(width)
  return self:configure({ border_width = width })
end

--- Set bar corner radius
--- @param radius number Corner radius in pixels
--- @return Bar
function Bar:corner_radius(radius)
  return self:configure({ corner_radius = radius })
end

--- Set bar blur radius
--- @param radius number Blur radius
--- @return Bar
function Bar:blur_radius(radius)
  return self:configure({ blur_radius = radius })
end

--- Set bar position
--- @param position "top"|"bottom" Bar position
--- @return Bar
function Bar:position(position)
  return self:configure({ position = position })
end

--- Set bar sticky behavior
--- @param sticky boolean Whether bar should be sticky
--- @return Bar
function Bar:sticky(sticky)
  return self:configure({ sticky = sticky })
end

--- Set bar padding
--- @param left number Left padding
--- @param right number Right padding
--- @return Bar
function Bar:padding(left, right)
  return self:configure({
    padding_left = left,
    padding_right = right
  })
end

--- Set bar margin
--- @param margin number Margin value
--- @return Bar
function Bar:margin(margin)
  return self:configure({ margin = margin })
end

--- Set bar y-offset
--- @param offset number Y-offset in pixels
--- @return Bar
function Bar:y_offset(offset)
  return self:configure({ y_offset = offset })
end

--- Set bar shadow
--- @param shadow boolean Whether to show shadow
--- @return Bar
function Bar:shadow(shadow)
  return self:configure({ shadow = shadow })
end

--- Hide the bar
--- @param hide boolean Whether to hide the bar
--- @return Bar
function Bar:hide(hide)
  return self:configure({ hidden = hide })
end

--- Set bar topmost behavior
--- @param topmost boolean Whether bar should be topmost
--- @return Bar
function Bar:topmost(topmost)
  return self:configure({ topmost = topmost })
end

--- Set bar font smoothing
--- @param smoothing boolean Whether to enable font smoothing
--- @return Bar
function Bar:font_smoothing(smoothing)
  return self:configure({ font_smoothing = smoothing })
end

--- Configure bar for specific display
--- @param display number Display number (1-based)
--- @return Bar
function Bar:display(display)
  return self:configure({ display = display })
end

--- Get current bar configuration
--- @return table Current configuration
function Bar:get_config()
  local config_copy = {}
  for k, v in pairs(self.config) do
    if type(v) == "table" then
      config_copy[k] = {}
      for k2, v2 in pairs(v) do
        config_copy[k][k2] = v2
      end
    else
      config_copy[k] = v
    end
  end
  return config_copy
end

--- Reset bar configuration to defaults
--- @return Bar
function Bar:reset()
  self.config = {}
  return self
end

--- Apply the current configuration to the bar
--- @return Bar
function Bar:apply()
  if not sbar then
    error("Bar not initialized. Call Bar.init(sbar) first.")
  end
  
  sbar.bar(self.config)
  return self
end

return Bar