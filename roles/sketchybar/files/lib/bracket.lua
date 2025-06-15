--- Bracket class for SketchyBar brackets
--- Handles creation and management of item brackets/groups
--- @class Bracket

local Bracket = {}
Bracket.__index = Bracket

--- @type table SbarLua instance
local sbar = nil

--- Initialize the Bracket class with SbarLua instance
--- @param sbar_instance table The SbarLua instance
function Bracket.init(sbar_instance)
  sbar = sbar_instance
end

--- Create a new Bracket instance
--- @param name string Bracket name/identifier
--- @param members table|string[] List of item names to include in bracket
--- @param config? table Initial bracket configuration
--- @return Bracket
function Bracket:new(name, members, config)
  if not sbar then
    error("Bracket not initialized. Call Bracket.init(sbar) first.")
  end
  
  local instance = setmetatable({}, Bracket)
  instance.name = name
  instance.members = members or {}
  instance.config = config or {}
  
  -- Create the bracket in sketchybar
  instance.sbar_bracket = sbar.add("bracket", instance.name, instance.members, instance.config)
  
  return instance
end

--- Set bracket properties
--- @param properties table Properties to set
--- @return Bracket
function Bracket:set(properties)
  if not self.sbar_bracket then
    error("Bracket not properly initialized")
  end
  
  for k, v in pairs(properties) do
    self.config[k] = v
  end
  self.sbar_bracket:set(properties)
  return self
end

--- Set bracket background properties
--- @param bg_config table Background configuration
--- @return Bracket
function Bracket:background(bg_config)
  return self:set({ background = bg_config })
end

--- Set background color
--- @param color number|string Background color
--- @return Bracket
function Bracket:bg_color(color)
  return self:background({ color = color })
end

--- Set background border color
--- @param color number|string Border color
--- @return Bracket
function Bracket:bg_border_color(color)
  return self:background({ border_color = color })
end

--- Set background border width
--- @param width number Border width in pixels
--- @return Bracket
function Bracket:bg_border_width(width)
  return self:background({ border_width = width })
end

--- Set background corner radius
--- @param radius number Corner radius in pixels
--- @return Bracket
function Bracket:bg_corner_radius(radius)
  return self:background({ corner_radius = radius })
end

--- Set background height
--- @param height number Background height in pixels
--- @return Bracket
function Bracket:bg_height(height)
  return self:background({ height = height })
end

--- Set bracket padding
--- @param left number Left padding
--- @param right number Right padding
--- @return Bracket
function Bracket:bg_padding(left, right)
  return self:background({
    padding_left = left,
    padding_right = right
  })
end

--- Set bracket y-offset
--- @param offset number Y-offset in pixels
--- @return Bracket
function Bracket:bg_y_offset(offset)
  return self:background({ y_offset = offset })
end

--- Set bracket shadow
--- @param shadow_config table Shadow configuration
--- @return Bracket
function Bracket:shadow(shadow_config)
  return self:set({ shadow = shadow_config })
end

--- Hide or show the bracket
--- @param hidden boolean Whether to hide the bracket
--- @return Bracket
function Bracket:hide(hidden)
  return self:set({ drawing = not hidden })
end

--- Add member items to the bracket
--- @param item_names string|string[] Item name(s) to add
--- @return Bracket
function Bracket:add_members(item_names)
  if type(item_names) == "string" then
    item_names = { item_names }
  end
  
  for _, name in ipairs(item_names) do
    table.insert(self.members, name)
  end
  
  -- Update the bracket with new members
  if self.sbar_bracket and self.sbar_bracket.set then
    self.sbar_bracket:set({ members = self.members })
  end
  
  return self
end

--- Remove member items from the bracket
--- @param item_names string|string[] Item name(s) to remove
--- @return Bracket
function Bracket:remove_members(item_names)
  if type(item_names) == "string" then
    item_names = { item_names }
  end
  
  for _, name_to_remove in ipairs(item_names) do
    for i, member in ipairs(self.members) do
      if member == name_to_remove then
        table.remove(self.members, i)
        break
      end
    end
  end
  
  -- Update the bracket with remaining members
  if self.sbar_bracket and self.sbar_bracket.set then
    self.sbar_bracket:set({ members = self.members })
  end
  
  return self
end

--- Set bracket members (replaces existing members)
--- @param members string[] List of item names
--- @return Bracket
function Bracket:set_members(members)
  self.members = members or {}
  
  if self.sbar_bracket and self.sbar_bracket.set then
    self.sbar_bracket:set({ members = self.members })
  end
  
  return self
end

--- Get current bracket members
--- @return string[] List of member item names
function Bracket:get_members()
  local members_copy = {}
  for i, member in ipairs(self.members) do
    members_copy[i] = member
  end
  return members_copy
end

--- Get bracket name
--- @return string Bracket name
function Bracket:get_name()
  return self.name
end

--- Get current bracket configuration
--- @return table Current configuration
function Bracket:get_config()
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

--- Query bracket properties from sketchybar
--- @param property? string Specific property to query
--- @return table Query results
function Bracket:query(property)
  if not self.sbar_bracket then
    error("Bracket not properly initialized")
  end
  
  if property then
    return self.sbar_bracket:query(property)
  else
    return self.sbar_bracket:query()
  end
end

--- Remove/delete the bracket
function Bracket:remove()
  if self.sbar_bracket and self.sbar_bracket.remove then
    self.sbar_bracket:remove()
  end
  self.sbar_bracket = nil
end

--- Subscribe to events
--- @param event string Event name
--- @param callback function Callback function
--- @return Bracket
function Bracket:subscribe(event, callback)
  if not self.sbar_bracket then
    error("Bracket not properly initialized")
  end
  
  self.sbar_bracket:subscribe(event, callback)
  return self
end

--- Set click script for the bracket
--- @param script_path string Path to the click script
--- @return Bracket
function Bracket:click_script(script_path)
  return self:set({ click_script = script_path })
end

return Bracket