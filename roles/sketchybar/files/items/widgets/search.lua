local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local Item = require("items.item")

---@param sbar SketchyBar
return function(sbar)
  local search_item = Item:new(sbar, "search", {
    icon = {
      align = "center",
      string = icons.search,
      padding_left = 2,
      padding_right = 2,
      font = {
        family = settings.font.numbers,
        size = 14,

      },
    },
    label = {
      drawing = false,
      padding_right = 10,
    },
    background = {
      padding_right = 5,
      color = colors.bar.bg,
      corner_radius = 50,
      height = 20,
    }
  })
  local search = search_item:render()

  search:subscribe(
    "mouse.clicked",
    function(_)
      sbar.exec("open -a 'Raycast'")
    end
  )

  search:subscribe("mouse.entered", function(_)
    sbar.animate("elastic", 12, function()
      search:set({
        icon = {
          color = colors.white,
          font = {
            size = 16
          },
        },
      })
    end)
  end)

  search:subscribe("mouse.exited", function(_)
    sbar.animate("elastic", 12, function()
      search:set({
        icon = {
          color = colors.icon.primary,
          font = {
            family = settings.font.numbers,
            size = 14,
          },
        },
      })
    end)
  end)
end
