local settings = require 'settings'

---@class Icons.weather
---@field sun string
---@field cloudy string
---@field cloud_sun string
---@field rain string
---@field snowflake string
---@field bolt string
---@field fog string
---@field mist string
---@field cloud_rain string

---@class Icons.switch
---@field on string
---@field off string

---@class Icons.volume
---@field _100 string
---@field _66 string
---@field _33 string
---@field _10 string
---@field _0 string

---@class Icons.battery
---@field _100 string
---@field _75 string
---@field _50 string
---@field _25 string
---@field _0 string
---@field charging string

---@class Icons.wifi
---@field upload string
---@field download string
---@field connected string
---@field disconnected string
---@field router string

---@class Icons.media
---@field icon string
---@field back string
---@field forward string
---@field play_pause string

---@class Icons
---@field arrow_up string
---@field arrow_down string
---@field arrow_left string
---@field arrow_right string
---@field plus string
---@field loading string
---@field apple string
---@field line string
---@field gear string
---@field cpu string
---@field clipboard string
---@field aqi string
---@field clock string
---@field spaces string
---@field menu string
---@field space_add string
---@field settings string
---@field cpu2 string
---@field circle_options string
---@field play string
---@field swap2 string
---@field start string
---@field start_on string
---@field circle_lines string
---@field circle_restart string
---@field circle_shutdown string
---@field circle_sleep string
---@field circle_power string
---@field circle_gear string
---@field circle_quit string
---@field circle_picker string
---@field circle_cal string
---@field circle_plus string
---@field circle_menu string
---@field search string
---@field mission_control string
---@field swap string
---@field user string
---
---@field weather Icons.weather
---@field switch Icons.switch
---@field volume Icons.volume
---@field battery Icons.battery
---@field wifi Icons.wifi
---@field media Icons.media

local icons = {
  ---@type Icons
  sf_symbols = {
    arrow_up = '􀆇',
    arrow_down = '􀆈',
    arrow_left = '􀁙',
    arrow_right = '􀆊',
    plus = '􀅼',
    loading = '􀖇',
    apple = '􀣺',
    line = '􀝷',
    gear = '􀍟',
    cpu = '􀧓',
    clipboard = '􀉄',
    aqi = '􀴿',
    clock = '􀐫',
    spaces = '􁏮',
    menu = '􀬑',
    space_add = '􀁍',
    settings = '􀍠',
    cpu2 = '􀎴',
    circle_options = '􀆕',
    play = '􀊈',
    swap2 = '􁌧',
    start = '􁓖',
    start_on = '􁌧',
    circle_lines = '􀧲',
    circle_restart = '􀖋',
    circle_shutdown = '􁾯',
    circle_sleep = '􀆼',
    circle_power = '􀷄',
    circle_gear = '􀺻',
    circle_quit = '􀁡',
    circle_picker = '􁾛',
    circle_cal = '􀐫',
    circle_plus = '􀁍',
    circle_menu = '􀧲',
    search = '􀊫',
    mission_control = '􀏨',
    swap = '􀺊',
    user = '􀓤',

    weather = {
      sun = '􀆬',
      cloudy = '􀇣',
      cloud_sun = '􀇕',
      rain = '􁷍',
      snowflake = '􀇏',
      bolt = '􀇟',
      fog = '􀇋',
      mist = '􁃛',
      cloud_rain = '􀇇',
    },

    switch = {
      on = '󰔡',
      off = '󰨙',
    },
    volume = {
      _100 = '􀊩',
      _66 = '􀊧',
      _33 = '􀊧',
      _10 = '􀊥',
      _0 = '􀊣',
    },
    battery = {
      _100 = '',
      _75 = '􀺸',
      _50 = '􀺶',
      _25 = '􀻂',
      _0 = '􀛪',
      charging = '􀢋',
    },
    wifi = {
      upload = '􀁯',
      download = '􀁱',
      connected = '󰖩',
      disconnected = '󰖪',
      router = '􁓣',
    },
    media = {
      icon = '󰝚',
      back = '􀊉',
      forward = '􀊋',
      play_pause = '􀊇',
    },
  },

  ---@type Icons
  nerdfont = {
    plus = '',
    loading = '',
    apple = '',
    gear = '',
    cpu = '',
    switch = {
      on = '􁏮',
      off = '􁏯',
    },
    volume = {
      _100 = '􀊩',
      _66 = '􀊩',
      _33 = '􀊧',
      _10 = '􀊥',
      _0 = '􀊣',
    },
    battery = {
      _100 = '',
      _75 = '',
      _50 = '',
      _25 = '',
      _0 = '',
      charging = '',
    },
    wifi = {
      upload = '􀄤',
      download = '􀓃',
      connected = '􀙇',
      disconnected = '􀙈',
      router = '􁓤',
    },
    media = {
      back = '􀊊',
      forward = '􀊌',
      play_pause = '􀊄',
    },
  },
}

local function select_icons()
  if settings.icons == 'nerdFont' then
    return icons.nerdfont
  else
    return icons.sf_symbols
  end
end

return select_icons()
