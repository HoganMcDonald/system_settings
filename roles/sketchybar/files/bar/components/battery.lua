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
    icon = { color = colors.green, font = { family = 'Hack Nerd Font:Bold', size = 16 } },
    background = {
      color = colors.with_alpha(colors.green, 0x16),
      border_color = colors.with_alpha(colors.green, 0x99),
      height = 28,
    },
    padding_left = 12,
    padding_right = 12,
  },
}
