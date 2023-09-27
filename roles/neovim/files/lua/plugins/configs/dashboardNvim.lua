-----------------------------------------------------------
-- Dashboard configuration file
-----------------------------------------------------------

-- Plugin: dashboard-nvim
-- https://github.com/glepnir/dashboard-nvim

local present, db = pcall(require, 'dashboard')

if not present then
  return
end

local colors = require('core.colors').get()
local fg = require('core.utils').fg

db.setup {
  theme = "doom",
  hide = {
    tabline = true,
    winbar = true,
    statusline = true,
  },

  config = {
    header = {
      '                                   ',
      '                                   ',
      '                                   ',
      '                                   ',
      '                                   ',
      '                                   ',
      '                                   ',
      '                                   ',
      '   ⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣿⣶⣿⣦⣼⣆          ',
      '    ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦       ',
      '          ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷    ⠻⠿⢿⣿⣧⣄     ',
      '           ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄    ',
      '          ⢠⣿⣿⣿⠈    ⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀   ',
      '   ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘  ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄  ',
      '  ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄   ',
      ' ⣠⣿⠿⠛ ⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄  ',
      ' ⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇ ⠛⠻⢷⣄ ',
      '      ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆     ',
      '       ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⣀⣤⣾⡿⠃     ',
      '                                   ',
    },

    center = {
      { desc = '  Find File                 SPC p f', action = 'Telescope find_files' },
      { desc = '  Recents                   SPC p o', action = 'Telescope oldfiles' },
      { desc = '  Find Word                 SPC f a', action = 'Telescope live_grep' },
      -- f = { description = { "  Load Last Session         SPC l  " }, command = "SessionLoad" },
    },

    footer = {
      '   ',
    },
  },
}

fg('DashboardHeader', colors.gold)
fg('DashboardCenter', colors.off_white)
