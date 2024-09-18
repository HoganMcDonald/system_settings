local Colors = require 'util.colors'
local fg = require('util.highlight').fg

return {
  -- dotenv
  {
    "ellisonleao/dotenv.nvim",
    lazy = false,
    opts = {
      enable_on_load = true, -- will load your .env file upon loading a buffer
      verbose = false,       -- show error notification if .env file is not found and if .env is loaded
    },
    config = function(_, opts)
      require('dotenv').setup(opts)
    end
  },

  -- start screen
  {
    'glepnir/dashboard-nvim',
    dependencies = 'kwsp/halcyon-neovim',
    opts = {
      theme = 'doom',
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
          { desc = ' Recents                   SPC p o', action = 'Telescope oldfiles' },
          { desc = '  Find Word                 SPC f a', action = 'Telescope live_grep' },
          -- f = { description = { "  Load Last Session         SPC l  " }, command = "SessionLoad" },
        },

        footer = {
          '   ',
        },
      },
    },
    config = function(_, opts)
      require('dashboard').setup(opts)
      fg('DashboardHeader', Colors.ACCENT)
      fg('DashboardCenter', Colors.FOREGROUND)
    end,
  },

  -- tmux integration
  {
    'alexghergh/nvim-tmux-navigation',
    lazy = false,
    keys = {
      {
        '˙',
        function()
          require('nvim-tmux-navigation').NvimTmuxNavigateLeft()
        end,
        silent = true,
      },
      {
        '∆',
        function()
          require('nvim-tmux-navigation').NvimTmuxNavigateDown()
        end,
        silent = true,
      },
      {
        '˚',
        function()
          require('nvim-tmux-navigation').NvimTmuxNavigateUp()
        end,
        silent = true,
      },
      {
        '¬',
        function()
          require('nvim-tmux-navigation').NvimTmuxNavigateRight()
        end,
        silent = true,
      },
      {
        '«',
        function()
          require('nvim-tmux-navigation').NvimTmuxNavigateLastActive()
        end,
        silent = true,
      },
      {
        '<M-space>',
        function()
          require('nvim-tmux-navigation').NvimTmuxNavigateNext()
        end,
        silent = true,
      },
    },
  },

  -- global notes
  {
    'backdround/global-note.nvim',
    keys = {
      {
        '<leader>n',
        function()
          require('global-note').toggle_note()
        end,
        desc = 'Toggle global note',
      },
    },
    config = true,
  },
}
