local colors   = require("colors")
local icons    = require("icons")
local settings = require("settings")
local Item = require("items.item")

---@param sbar SketchyBar
return function(sbar)
	local mission_item = Item:new(sbar, "mission_control", {
		icon = {
			align = "center",
			padding_left = 10,
			padding_right = 10,
			string = icons.mission_control,
			font = {
				size = 12,
				family = settings.font.numbers,

			},
		},
		label = {
			drawing = false,
		}

	})
	local mission = mission_item:render()


	mission:subscribe(
		"mouse.clicked",
		function(env)
			sbar.exec("open -a 'Mission Control'")
		end
	)

	mission:subscribe("mouse.entered", function(env)
		sbar.animate("sin", 15, function()
			mission:set({
				icon = {
					color = colors.white,
					font = {
						family = settings.font.numbers,
						size = 18,

					},
				},
			})
		end)
	end)

	mission:subscribe("mouse.exited", function(env)
		sbar.animate("elastic", 12, function()
			mission:set({

				icon = {
					color = colors.icon.primary,
					font = {
						size = 12,
						family = settings.font.numbers,

					},
				},
			})
		end)
	end)
end
