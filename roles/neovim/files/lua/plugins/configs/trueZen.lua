-----------------------------------------------------------
-- zen mode configuration file
-----------------------------------------------------------

-- Plugin: true-zen
-- https://github.com/Pocco81/true-zen.nvim

local present, zen = pcall(require, 'true-zen')

if not present then
  return
end

zen.setup({
  modes = {
    ataraxis = {
      shade = "dark", -- if `dark` then dim the padding windows, otherwise if it's `light` it'll brighten said windows
      backdrop = 0, -- percentage by which padding windows should be dimmed/brightened. Must be a number between 0 and 1. Set to 0 to keep the same background color
      minimum_writing_area = { -- minimum size of main window
        width = 70,
        height = 44,
      },
      quit_untoggles = true, -- type :q or :qa to quit Ataraxis mode
      padding = { -- padding windows
        left = 52,
        right = 52,
        top = 0,
        bottom = 0,
      },
      callbacks = { -- run functions when opening/closing Ataraxis mode
        open_pre = nil,
        open_pos = nil,
        close_pre = nil,
        close_pos = nil
      },
    },
  },
  integrations = {
    tmux = false, -- hide tmux status bar in (minimalist, ataraxis)
    kitty = { -- increment font size in Kitty. Note: you must set `allow_remote_control socket-only` and `listen_on unix:/tmp/kitty` in your personal config (ataraxis)
      enabled = true,
      font = "+8"
    },
    twilight = false, -- enable twilight (ataraxis)
    lualine = true -- hide nvim-lualine (ataraxis)
  },
})
