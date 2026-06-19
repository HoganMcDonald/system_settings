--- Declarative renderer for sketchybar specs.
--- Walks a single spec table and issues sbar.add/sbar.bar calls,
--- wiring Lua handlers, animations, and popup sub-trees.

---@class ScriptSpec
---@field path string Filename relative to PLUGIN_DIR, or absolute / ~-prefixed path.
---@field every? number update_freq in seconds.

---@alias Curve "linear"|"ease_in"|"ease_out"|"ease_in_out"|"bounce"|"overshoot"

---@class AnimateSpec
---@field duration number Seconds.
---@field curve? Curve Default ease_in_out.
---@field to table Properties to animate to.

---@alias AnimFn fun(name: string)
---@alias Handler fun(item: table, env: table, anim: AnimFn)

---@class PopupItemSpec
---@field name string Suffix; final item name is "<parent>.<name>".
---@field props? table
---@field on_click? string|Handler

---@class PopupSpec
---@field background? table Bracket-like background for the popup container.
---@field items? PopupItemSpec[]

---@class ComponentSpec
---@field name string Unique sketchybar item name.
---@field position? "left"|"center"|"right" Overrides the region.
---@field props? table Raw sketchybar item properties.
---@field script? string|ScriptSpec Shell plugin (legacy path).
---@field every? number update_freq for on_update.
---@field on_update? Handler Fires on routine/forced updates.
---@field on_click? string|Handler Shell path or Lua handler.
---@field on? table<string, Handler> Event-name → handler map.
---@field subscribe? string[] Plain event subscription (script handles them).
---@field animate? table<string, AnimateSpec> Named animations, played via anim('name').
---@field popup? PopupSpec
---@field group_name? string If set, item joins this bracket group.

---@class GroupHeader
---@field name string Bracket name.
---@field props? table Raw bracket properties.

---@class GroupSpec
---@field group GroupHeader
---@field items ComponentSpec[]

---@class BarSpec
---@field bar? table Raw sketchybar bar properties.
---@field events? string[] Custom events to register.
---@field defaults? table Property defaults deep-merged into every item.
---@field left? (ComponentSpec|GroupSpec)[]
---@field center? (ComponentSpec|GroupSpec)[]
---@field right? (ComponentSpec|GroupSpec)[]

local M = {}

local sbar = nil

local PLUGIN_DIR = "~/.config/sketchybar/plugins/"

local SPEC_KEYS = { bar = true, events = true, defaults = true, left = true, center = true, right = true }
local COMPONENT_KEYS = {
  name = true,
  position = true,
  props = true,
  script = true,
  every = true,
  on_update = true,
  on_click = true,
  on = true,
  subscribe = true,
  animate = true,
  popup = true,
  group_name = true,
}
local POPUP_KEYS = { background = true, items = true }
local POPUP_ITEM_KEYS = { name = true, props = true, on_click = true }
local GROUP_KEYS = { group = true, items = true }
local GROUP_HEADER_KEYS = { name = true, props = true }
local SCRIPT_KEYS = { path = true, every = true }
local ANIMATE_KEYS = { duration = true, curve = true, to = true }
local VALID_POSITIONS = { left = true, center = true, right = true, q = true, e = true }
local VALID_CURVES = { linear = true, ease_in = true, ease_out = true, ease_in_out = true, bounce = true, overshoot = true }

local function deep_copy(t)
  if type(t) ~= "table" then
    return t
  end
  local out = {}
  for k, v in pairs(t) do
    out[k] = deep_copy(v)
  end
  return out
end

local function deep_merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deep_merge(dst[k], v)
    else
      dst[k] = v
    end
  end
  return dst
end

local function check_keys(where, tbl, allowed)
  for k in pairs(tbl) do
    if not allowed[k] then
      error(string.format("[sketchybar] %s: unknown key '%s'", where, tostring(k)), 0)
    end
  end
end

local function expand_home(path)
  if path:sub(1, 1) == "~" then
    return (os.getenv("HOME") or "") .. path:sub(2)
  end
  return path
end

local function file_exists(path)
  local f = io.open(expand_home(path), "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function is_shell_command(s)
  return s:match("^%a[%w_-]*%s") ~= nil
end

local function resolve_script(s)
  if not s then
    return nil
  end
  local first = s:sub(1, 1)
  if first == "/" or first == "~" or is_shell_command(s) then
    return s
  end
  return PLUGIN_DIR .. s
end

local function validate_script(where, script)
  if type(script) == "string" then
    if not is_shell_command(script) and not file_exists(resolve_script(script)) then
      error(string.format("[sketchybar] %s: script '%s' not found", where, script), 0)
    end
  elseif type(script) == "table" then
    check_keys(where .. ".script", script, SCRIPT_KEYS)
    if type(script.path) ~= "string" then
      error(string.format("[sketchybar] %s: script.path must be a string", where), 0)
    end
    if not file_exists(resolve_script(script.path)) then
      error(string.format("[sketchybar] %s: script '%s' not found", where, script.path), 0)
    end
  else
    error(string.format("[sketchybar] %s: script must be a string or { path, every }", where), 0)
  end
end

local function validate_click(where, on_click)
  local t = type(on_click)
  if t == "function" then
    return
  end
  if t ~= "string" then
    error(string.format("[sketchybar] %s.on_click: must be a string or function", where), 0)
  end
  if not is_shell_command(on_click) and not file_exists(resolve_script(on_click)) then
    error(string.format("[sketchybar] %s.on_click: '%s' not found", where, on_click), 0)
  end
end

local function validate_animate(where, animate)
  for name, spec in pairs(animate) do
    local label = string.format("%s.animate.%s", where, name)
    if type(spec) ~= "table" then
      error(label .. ": must be a table", 0)
    end
    check_keys(label, spec, ANIMATE_KEYS)
    if type(spec.duration) ~= "number" then
      error(label .. ": duration must be a number", 0)
    end
    if spec.curve ~= nil and not VALID_CURVES[spec.curve] then
      error(string.format("%s: invalid curve '%s'", label, tostring(spec.curve)), 0)
    end
    if type(spec.to) ~= "table" then
      error(label .. ": 'to' must be a table of properties", 0)
    end
  end
end

local function validate_popup(where, popup)
  check_keys(where .. ".popup", popup, POPUP_KEYS)
  if popup.items ~= nil then
    if type(popup.items) ~= "table" then
      error(where .. ".popup.items must be a list", 0)
    end
    for i, sub in ipairs(popup.items) do
      local label = string.format("%s.popup.items[%d]", where, i)
      check_keys(label, sub, POPUP_ITEM_KEYS)
      if type(sub.name) ~= "string" or sub.name == "" then
        error(label .. ": missing 'name'", 0)
      end
      if sub.on_click ~= nil then
        if type(sub.on_click) ~= "string" then
          error(label .. ".on_click: must be a string (popup items are created via CLI)", 0)
        end
        validate_click(label, sub.on_click)
      end
    end
  end
end

local function validate_component(where, c)
  check_keys(where, c, COMPONENT_KEYS)
  if type(c.name) ~= "string" or c.name == "" then
    error(string.format("[sketchybar] %s: missing 'name'", where), 0)
  end
  if c.position ~= nil and not VALID_POSITIONS[c.position] then
    error(string.format("[sketchybar] %s: invalid position '%s'", where, tostring(c.position)), 0)
  end
  if c.script ~= nil then
    validate_script(where, c.script)
  end
  if c.on_click ~= nil then
    validate_click(where, c.on_click)
  end
  if c.on_update ~= nil and type(c.on_update) ~= "function" then
    error(string.format("[sketchybar] %s.on_update: must be a function", where), 0)
  end
  if c.every ~= nil and type(c.every) ~= "number" then
    error(string.format("[sketchybar] %s.every: must be a number", where), 0)
  end
  if c.on ~= nil then
    if type(c.on) ~= "table" then
      error(string.format("[sketchybar] %s.on: must be a table of event → function", where), 0)
    end
    for ev, fn in pairs(c.on) do
      if type(ev) ~= "string" then
        error(string.format("[sketchybar] %s.on: event names must be strings", where), 0)
      end
      if type(fn) ~= "function" then
        error(string.format("[sketchybar] %s.on.%s: must be a function", where, ev), 0)
      end
    end
  end
  if c.subscribe ~= nil and type(c.subscribe) ~= "table" then
    error(string.format("[sketchybar] %s.subscribe: must be a list of event names", where), 0)
  end
  if c.animate ~= nil then
    if type(c.animate) ~= "table" then
      error(string.format("[sketchybar] %s.animate: must be a table", where), 0)
    end
    validate_animate(where, c.animate)
  end
  if c.popup ~= nil then
    validate_popup(where, c.popup)
  end
end

local function validate_group(where, g)
  check_keys(where, g, GROUP_KEYS)
  if type(g.group) ~= "table" then
    error(string.format("[sketchybar] %s: group must be a table { name, props? }", where), 0)
  end
  check_keys(where .. ".group", g.group, GROUP_HEADER_KEYS)
  if type(g.group.name) ~= "string" or g.group.name == "" then
    error(string.format("[sketchybar] %s.group: missing 'name'", where), 0)
  end
  if type(g.items) ~= "table" or #g.items == 0 then
    error(string.format("[sketchybar] %s: group needs non-empty 'items'", where), 0)
  end
  for i, item in ipairs(g.items) do
    validate_component(string.format("%s.items[%d](%s)", where, i, tostring(item.name)), item)
  end
end

local function validate_region(region_key, components)
  if components == nil then
    return
  end
  if type(components) ~= "table" then
    error(string.format("[sketchybar] %s must be a list", region_key), 0)
  end
  for i, c in ipairs(components) do
    local where = string.format("%s[%d]", region_key, i)
    if c.group ~= nil or c.items ~= nil then
      validate_group(where, c)
    else
      validate_component(where, c)
    end
  end
end

---@param spec BarSpec
local function validate(spec)
  if type(spec) ~= "table" then
    error("[sketchybar] spec must be a table", 0)
  end
  check_keys("spec", spec, SPEC_KEYS)
  if spec.events ~= nil and type(spec.events) ~= "table" then
    error("[sketchybar] spec.events must be a list of event names", 0)
  end
  validate_region("left", spec.left)
  validate_region("center", spec.center)
  validate_region("right", spec.right)
end

local function build_anim(item, animate_map)
  if not animate_map then
    return function() end
  end
  return function(name)
    local a = animate_map[name]
    if not a then
      error("[sketchybar] animation '" .. tostring(name) .. "' not declared", 0)
    end
    sbar.animate(a.curve or "ease_in_out", a.duration, function()
      item:set(a.to)
    end)
  end
end

local click_event_counter = 0

--- Wire an on_click handler. For Lua functions we route through a synthetic
--- event triggered by click_script — `mouse.clicked` has multi-click debounce
--- latency that makes it feel sluggish.
local function wire_click(item, name, on_click, anim)
  if not on_click then
    return
  end
  if type(on_click) == "function" then
    click_event_counter = click_event_counter + 1
    local event = "render.click." .. name:gsub("%.", "_") .. "." .. click_event_counter
    sbar.add("event", event)
    item:set({ click_script = "sketchybar --trigger " .. event })
    item:subscribe(event, function(env)
      on_click(item, env, anim)
    end)
  else
    item:set({ click_script = resolve_script(on_click) })
  end
end

local function build_props(item_spec, defaults)
  local props = deep_copy(defaults or {})
  deep_merge(props, item_spec.props or {})

  if item_spec.script then
    if type(item_spec.script) == "string" then
      props.script = resolve_script(item_spec.script)
    else
      props.script = resolve_script(item_spec.script.path)
      if item_spec.script.every then
        props.update_freq = item_spec.script.every
      end
    end
  end

  if item_spec.on_update then
    props.update_freq = item_spec.every or 0
  end

  if type(item_spec.on_click) == "string" then
    props.click_script = resolve_script(item_spec.on_click)
  end

  if item_spec.popup then
    local popup = deep_copy(props.popup or {})
    if item_spec.popup.background then
      popup.background = deep_merge(popup.background or {}, item_spec.popup.background)
    end
    if popup.drawing == nil then
      popup.drawing = false
    end
    props.popup = popup
  end

  return props
end

local function shell_quote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function flatten_props(props, prefix, out)
  out = out or {}
  prefix = prefix or ""
  for k, v in pairs(props) do
    local key = prefix == "" and k or (prefix .. "." .. k)
    if type(v) == "table" then
      flatten_props(v, key, out)
    elseif type(v) == "boolean" then
      table.insert(out, key .. "=" .. (v and "on" or "off"))
    elseif type(v) == "number" then
      if key:match("color") or key:match("border_color") then
        table.insert(out, string.format("%s=0x%08x", key, v))
      else
        table.insert(out, key .. "=" .. tostring(v))
      end
    else
      table.insert(out, key .. "=" .. shell_quote(v))
    end
  end
  return out
end

local function add_popup_items(parent, popup_items, defaults)
  if not popup_items then
    return
  end
  for _, sub in ipairs(popup_items) do
    local full_name = parent .. "." .. sub.name
    local props = deep_copy(defaults or {})
    deep_merge(props, sub.props or {})
    if sub.on_click then
      props.click_script = resolve_script(sub.on_click)
    end
    local position = "popup." .. parent
    props.position = position
    local item = sbar.add("item", full_name, props)
    item:set({ position = position })
  end
end

local function add_item(item_spec, defaults, region_position)
  local props = build_props(item_spec, defaults)
  local position = item_spec.position or region_position
  props.position = position
  local item = sbar.add("item", item_spec.name, props)
  item:set({ position = position })

  local anim = build_anim(item, item_spec.animate)

  if item_spec.on_update then
    item:subscribe("routine", function(env)
      item_spec.on_update(item, env, anim)
    end)
    item:subscribe("forced", function(env)
      item_spec.on_update(item, env, anim)
    end)
  end

  if item_spec.on then
    for event, fn in pairs(item_spec.on) do
      item:subscribe(event, function(env)
        fn(item, env, anim)
      end)
    end
  end

  if type(item_spec.on_click) == "function" then
    wire_click(item, item_spec.name, item_spec.on_click, anim)
  elseif item_spec.popup and item_spec.popup.items and item_spec.on_click == nil then
    -- Default: clicking the parent toggles the popup. Synchronous via click_script.
    item:set({ click_script = "sketchybar --set " .. item_spec.name .. " popup.drawing=toggle" })
  end

  -- Subscribe events are handled by sketchybar's script system.
  -- For Lua callbacks, use the 'on' field instead.
  -- if item_spec.subscribe and #item_spec.subscribe > 0 then
  --   item:set({ subscribe = item_spec.subscribe })
  -- end

  if item_spec.popup and item_spec.popup.items then
    add_popup_items(item_spec.name, item_spec.popup.items, defaults)
  end

  return item
end

function M.init(sbar_instance)
  sbar = sbar_instance
end

--- Render a bar spec. Validates first; throws on unknown keys, missing
--- scripts, or malformed components.
---@param spec BarSpec
function M.render(spec)
  validate(spec)

  if spec.bar then
    sbar.bar(spec.bar)
  end

  for _, ev in ipairs(spec.events or {}) do
    sbar.add("event", ev)
  end

  local defaults = spec.defaults or {}
  local groups = {}
  local group_order = {}

  local function record_group(name, props, region)
    if not groups[name] then
      groups[name] = { members = {}, props = props or {}, position = region }
      table.insert(group_order, name)
    end
    return groups[name]
  end

  local function process(region_key, region_position)
    for _, component in ipairs(spec[region_key] or {}) do
      if component.group and component.items then
        local g = record_group(component.group.name, component.group.props, region_position)
        for _, item_spec in ipairs(component.items) do
          add_item(item_spec, defaults, region_position)
          table.insert(g.members, item_spec.name)
        end
      else
        add_item(component, defaults, region_position)
        if component.group_name then
          local g = record_group(component.group_name, nil, region_position)
          table.insert(g.members, component.name)
        end
      end
    end
  end

  process("left", "left")
  process("center", "center")
  process("right", "right")

  for _, name in ipairs(group_order) do
    local g = groups[name]
    local props = deep_copy(g.props)
    props.position = props.position or g.position
    sbar.add("bracket", name, g.members, props)
  end
end

return M
