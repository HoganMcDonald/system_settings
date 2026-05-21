local colors = require('colors')

local function pmset()
  local f = io.popen('pmset -g batt')
  if not f then
    return nil, false
  end
  local out = f:read('*a') or ''
  f:close()
  local pct = tonumber(out:match('(%d+)%%'))
  local charging = out:find('AC Power') ~= nil
  return pct, charging
end

local function icon_for(pct, charging)
  if charging then
    return '\u{F008B}', 0xfff1ff5e
  end
  if pct >= 80 then
    return '\u{F008C}', 0xff5eff6b
  end
  if pct >= 70 then
    return '\u{F00FA}', 0xfff1ff5e
  end
  if pct >= 40 then
    return '\u{F00F8}', 0xffffbd5e
  end
  if pct >= 10 then
    return '\u{F008D}', 0xffff6e5e
  end
  return '\u{F008E}', 0xffff6e5e
end

local function refresh(item)
  local pct, charging = pmset()
  if not pct then
    return
  end
  local icon, color = icon_for(pct, charging)
  item:set {
    icon = { string = icon, color = color, padding_right = 5 },
    label = { string = pct .. '%' },
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
    item:set { popup = { drawing = 'toggle' } }
  end,
  props = {
    label = { color = colors.text },
    icon = { color = colors.green, font = { family = 'SF Pro Display', size = 16 } },
    padding_left = 5,
    padding_right = 5,
  },
}
