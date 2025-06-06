sbar = require("sketchybar")

-- Load the appropriate color file
local colors

if is_dark_mode() then
    colors = require("colors_dark")
else
    colors = require("colors_light")
end

----------------------------------

local icons = require("icons")
local settings = require("settings")

-- Determine which bar configuration to load
local bar_config = os.getenv("BAR_CONFIG") or "bar" -- Defaults to "bar.lua"

sbar.begin_config()

require("default")
sbar.animate("tanh", 25, function()
    require("items")
    require("bar") -- Load bar.lua or bar-full.lua dynamically
end)
sbar.end_config()

sbar.event_loop()
