return {
  -- CodeCompanion
  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'hrsh7th/nvim-cmp', -- Optional: For using slash commands and variables in the chat buffer
      'nvim-telescope/telescope.nvim', -- Optional: For using slash commands
      "banjo/contextfiles.nvim",
      { 'stevearc/dressing.nvim', opts = {} }, -- Optional: Improves `vim.ui.select`
      {
        'ravitemer/mcphub.nvim',
        cmd = 'MCPHub',
        build = 'npm install -g mcp-hub@latest',
        config = function()
          require('mcphub').setup {
            -- Required options
            port = 3000,
            config = vim.fn.expand '~/.config/mcp-hub/config.json',
          }
        end,
      },
    },
    keys = {
      { '<leader>aa', ':CodeCompanionActions<cr>', desc = 'Open CodeCompanion Commands', mode = { 'n', 'v' } },
    },
    config = {
      adapters = {
        anthropic = function()
          return require('codecompanion.adapters').extend('anthropic', {
            env = {
              api_key = require('dotenv').get { 'ANTHROPIC_API_KEY' },
            },
          })
        end,
        openai = function()
          return require('codecompanion.adapters').extend('openai', {
            env = {
              api_key = require('dotenv').get { 'OPENAI_API_KEY' },
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = 'anthropic',
          tools = {
            ['mcp'] = {
              -- calling it in a function would prevent mcphub from being loaded before it's needed
              callback = function()
                return require 'mcphub.extensions.codecompanion'
              end,
              description = 'Call tools and resources from the MCP Servers',
              opts = {
                requires_approval = false,
              },
            },
          },
        },
        inline = {
          adapter = 'openai',
        },
      },
    },
  },

  -- Copilot
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {},
    config = function()
      require('copilot').setup {}
    end,
  },

  {
    'zbirenbaum/copilot-cmp',
    dependencies = {
      'zbirenbaum/copilot.lua',
    },
    config = function()
      require('copilot_cmp').setup()
    end,
  },

  {
    'AndreM222/copilot-lualine',
    dependencies = {
      'zbirenbaum/copilot.lua',
    },
  },
}
