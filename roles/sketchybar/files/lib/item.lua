--- Item class for SketchyBar items
--- Handles creation, configuration and management of bar items
--- @class Item

local Item = {}
Item.__index = Item

--- @type table SbarLua instance
local sbar = nil

--- Initialize the Item class with SbarLua instance
--- @param sbar_instance table The SbarLua instance
function Item.init(sbar_instance)
  sbar = sbar_instance
end

--- Create a new Item instance
--- @param item_type? string Type of item ("item", "space", "alias")
--- @param name? string Item name/identifier
--- @param position? string Position ("left", "right", "center", "q", "e")
--- @param config? table Initial item configuration
--- @return Item
function Item:new(item_type, name, position, config)
  if not sbar then
    error("Item not initialized. Call Item.init(sbar) first.")
  end
  
  local instance = setmetatable({}, Item)
  instance.type = item_type or "item"
  instance.name = name
  instance.position = position or "right"
  instance.config = config or {}
  
  -- Create the item in sketchybar
  instance.sbar_item = sbar.add(instance.type, instance.name, instance.position, instance.config)
  
  return instance
end

--- Set item properties
--- @param properties table Properties to set
--- @return Item
function Item:set(properties)
  if not self.sbar_item then
    error("Item not properly initialized")
  end
  
  for k, v in pairs(properties) do
    self.config[k] = v
  end
  self.sbar_item:set(properties)
  return self
end

--- Set item icon properties
--- @param icon_config table Icon configuration
--- @return Item
function Item:icon(icon_config)
  return self:set({ icon = icon_config })
end

--- Set item label properties
--- @param label_config table Label configuration
--- @return Item
function Item:label(label_config)
  return self:set({ label = label_config })
end

--- Set item background properties
--- @param bg_config table Background configuration
--- @return Item
function Item:background(bg_config)
  return self:set({ background = bg_config })
end

--- Set item script
--- @param script_path string Path to the script
--- @param update_freq? number Update frequency in seconds
--- @return Item
function Item:script(script_path, update_freq)
  local script_config = {
    script = script_path
  }
  
  if update_freq then
    script_config.update_freq = update_freq
  end
  
  return self:set(script_config)
end

--- Subscribe to events
--- @param event string Event name
--- @param callback function Callback function
--- @return Item
function Item:subscribe(event, callback)
  if not self.sbar_item then
    error("Item not properly initialized")
  end
  
  self.sbar_item:subscribe(event, callback)
  return self
end

--- Set item position
--- @param position string Position ("left", "right", "center", "q", "e")
--- @return Item
function Item:move_to(position)
  self.position = position
  return self:set({ position = position })
end

--- Set item width
--- @param width number Width in pixels
--- @return Item
function Item:width(width)
  return self:set({ width = width })
end

--- Set item padding
--- @param left number Left padding
--- @param right number Right padding
--- @return Item
function Item:padding(left, right)
  return self:set({
    padding_left = left,
    padding_right = right
  })
end

--- Set item y-offset
--- @param offset number Y-offset in pixels
--- @return Item
function Item:y_offset(offset)
  return self:set({ y_offset = offset })
end

--- Hide or show the item
--- @param hidden boolean Whether to hide the item
--- @return Item
function Item:hide(hidden)
  return self:set({ drawing = not hidden })
end

--- Set item click script
--- @param script_path string Path to the click script
--- @return Item
function Item:click_script(script_path)
  return self:set({ click_script = script_path })
end

--- Set icon string
--- @param icon_str string Icon string/text
--- @return Item
function Item:icon_string(icon_str)
  return self:icon({ string = icon_str })
end

--- Set icon color
--- @param color number|string Icon color
--- @return Item
function Item:icon_color(color)
  return self:icon({ color = color })
end

--- Set icon font
--- @param font string Font family
--- @param size? number Font size
--- @return Item
function Item:icon_font(font, size)
  local font_config = { family = font }
  if size then
    font_config.size = size
  end
  return self:icon({ font = font_config })
end

--- Set label string
--- @param label_str string Label text
--- @return Item
function Item:label_string(label_str)
  return self:label({ string = label_str })
end

--- Set label color
--- @param color number|string Label color
--- @return Item
function Item:label_color(color)
  return self:label({ color = color })
end

--- Set label font
--- @param font string Font family
--- @param size? number Font size
--- @return Item
function Item:label_font(font, size)
  local font_config = { family = font }
  if size then
    font_config.size = size
  end
  return self:label({ font = font_config })
end

--- Set background color
--- @param color number|string Background color
--- @return Item
function Item:bg_color(color)
  return self:background({ color = color })
end

--- Set background border color
--- @param color number|string Border color
--- @return Item
function Item:bg_border_color(color)
  return self:background({ border_color = color })
end

--- Set background border width
--- @param width number Border width
--- @return Item
function Item:bg_border_width(width)
  return self:background({ border_width = width })
end

--- Set background corner radius
--- @param radius number Corner radius
--- @return Item
function Item:bg_corner_radius(radius)
  return self:background({ corner_radius = radius })
end

--- Set background height
--- @param height number Background height
--- @return Item
function Item:bg_height(height)
  return self:background({ height = height })
end

--- Set item shadow
--- @param shadow_config table Shadow configuration
--- @return Item
function Item:shadow(shadow_config)
  return self:set({ shadow = shadow_config })
end

--- Set associated space (for space items)
--- @param space number Space number
--- @return Item
function Item:associated_space(space)
  return self:set({ associated_space = space })
end

--- Set associated display (for space items)
--- @param display number Display number
--- @return Item
function Item:associated_display(display)
  return self:set({ associated_display = display })
end

--- Set item alias (for alias items)
--- @param app_name string Application name
--- @return Item
function Item:alias_app(app_name)
  return self:set({ alias = app_name })
end

--- Get current item configuration
--- @return table Current configuration
function Item:get_config()
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

--- Get item name
--- @return string Item name
function Item:get_name()
  return self.name
end

--- Get item type
--- @return string Item type
function Item:get_type()
  return self.type
end

--- Get item position
--- @return string Item position
function Item:get_position()
  return self.position
end

--- Query item properties from sketchybar
--- @param property? string Specific property to query
--- @return table Query results
function Item:query(property)
  if not self.sbar_item then
    error("Item not properly initialized")
  end
  
  if property then
    return self.sbar_item:query(property)
  else
    return self.sbar_item:query()
  end
end

--- Remove/delete the item
function Item:remove()
  if self.sbar_item and self.sbar_item.remove then
    self.sbar_item:remove()
  end
  self.sbar_item = nil
end

--- Clone the item with a new name
--- @param new_name string New item name
--- @return Item New item instance
function Item:clone(new_name)
  if not self.sbar_item then
    error("Item not properly initialized")
  end
  
  local cloned_sbar_item = self.sbar_item:clone(new_name)
  local cloned_item = setmetatable({}, Item)
  cloned_item.type = self.type
  cloned_item.name = new_name
  cloned_item.position = self.position
  cloned_item.config = self:get_config()
  cloned_item.sbar_item = cloned_sbar_item
  
  return cloned_item
end

return Item