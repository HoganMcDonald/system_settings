local colors    = require("colors")
local icons     = require("icons")
local settings  = require("settings")
local Item = require("items.item")

---@param sbar SketchyBar
return function(sbar)
	local add_space_item = Item:new(sbar, "add_space", {
		icon = {
			align = "center",
			padding_left = 15,
			padding_right = 10,
			string = icons.plus,
		},
		label = {
			drawing = false,
		},

	})
	local add_space = add_space_item:render()


	add_space:subscribe("mouse.entered", function(env)
		sbar.animate("sin", 15, function()
			add_space:set({
				icon = {
					color = colors.white,
					font = {
						family = settings.font.numbers,
						size = 18,

					},
					click_csript = 'osascript -e "$CONFIG_DIR/items/scripts/switchSpace/newSpace.scpt"'
				},
			})
		end)
	end)

	add_space:subscribe("mouse.exited", function(env)
		sbar.animate("elastic", 12, function()
			add_space:set({

				icon = {
					color = colors.icon.primary,
					font = {
						size = 14,
						family = settings.font.numbers,

					},
				},
			})
		end)
	end)
end
