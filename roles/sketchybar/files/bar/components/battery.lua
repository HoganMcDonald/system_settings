local colors = require 'colors'

local STATE_FILE = '/tmp/sketchybar_battery_time'

local function pmset()
  local f = io.popen 'pmset -g batt'
  if not f then
    return nil, false
  end
  local out = f:read '*a' or ''
  f:close()
  local pct = tonumber(out:match '(%d+)%%')
  local charging = out:find 'AC Power' ~= nil
  return pct, charging, out
end

local function showing_time()
  local f = io.open(STATE_FILE, 'r')
  if f then
    f:close()
    return true
  end
  return false
end

local function toggle_time()
  if showing_time() then
    os.remove(STATE_FILE)
    return
  end

  local f = io.open(STATE_FILE, 'w')
  if f then
    f:close()
  end
end

local function time_label(out, charging)
  if charging then
    return out:match '(%d+:%d+) remaining to full charge' or 'Charging'
  end

  return out:match '(%d+:%d+) remaining' or 'Calculating...'
end

local function icon_for(pct, charging)
  if charging then
    return '\u{F008B}', colors.amber
  end
  if pct >= 80 then
    return '\u{F008C}', colors.green
  end
  if pct >= 70 then
    return '\u{F00FA}', colors.amber
  end
  if pct >= 40 then
    return '\u{F00F8}', colors.warning
  end
  if pct >= 10 then
    return '\u{F008D}', colors.critical
  end
  return '\u{F008E}', colors.critical
end

local function refresh(item)
  local pct, charging, out = pmset()
  if not pct then
    return
  end
  local icon, color = icon_for(pct, charging)
  local label = showing_time() and time_label(out, charging) or pct .. '%'
  item:set {
    icon = { string = icon, color = color, padding_left = 8, padding_right = 5 },
    label = { string = label, padding_right = 9 },
  }
end

---@type ComponentSpec
return {
  name = 'battery',
  every = 120,
  on_update = refresh,
  on = {
    power_source_change = refresh,
    system_woke = refresh,
  },
  on_click = function(item)
    toggle_time()
    refresh(item)
  end,
  props = {
    label = { color = colors.text, padding_right = 9 },
    icon = { color = colors.green, font = { family = 'Hack Nerd Font:Bold', size = 16 }, padding_left = 8, padding_right = 5 },
    background = {
      color = colors.with_alpha(colors.green, 0x24),
      border_color = colors.with_alpha(colors.green, 0x99),
      height = 28,
    },
    padding_left = 4,
    padding_right = 4,
  },
}
