return {
  -- codeium (use through cmp)
  {
    'Exafunction/codeium.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'hrsh7th/nvim-cmp',
    },
    config = function()
      require('codeium').setup {}
    end,
  },

  -- {
  --   'yetone/avante.nvim',
  --   event = 'VeryLazy',
  --   lazy = false,
  --   version = false, -- set this if you want to always pull the latest change
  --   opts = {
  --     ---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | string
  --     provider = 'claude', -- Recommend using Claude
  --     behaviour = {
  --       auto_suggestions = false, -- Experimental stage
  --       auto_set_highlight_group = true,
  --       auto_set_keymaps = true,
  --       auto_apply_diff_after_generation = true,
  --       support_paste_from_clipboard = true,
  --     },
  --     windows = {
  --       sidebar_header = {
  --         rounded = false,
  --       },
  --     },
  --   },
  --   -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  --   build = 'make',
  --   -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  --   dependencies = {
  --     'stevearc/dressing.nvim',
  --     'nvim-lua/plenary.nvim',
  --     'MunifTanjim/nui.nvim',
  --     --- The below dependencies are optional,
  --     'nvim-tree/nvim-web-devicons', -- or echasnovski/mini.icons
  --     -- 'zbirenbaum/copilot.lua', -- for providers='copilot'
  --     {
  --       -- support for image pasting
  --       'HakonHarnes/img-clip.nvim',
  --       event = 'VeryLazy',
  --       opts = {
  --         -- recommended settings
  --         default = {
  --           embed_image_as_base64 = false,
  --           prompt_for_file_name = false,
  --           drag_and_drop = {
  --             insert_mode = true,
  --           },
  --           -- required for Windows users
  --           use_absolute_path = true,
  --         },
  --       },
  --     },
  --     {
  --       -- Make sure to set this up properly if you have lazy=true
  --       'MeanderingProgrammer/render-markdown.nvim',
  --       opts = {
  --         file_types = { 'markdown', 'Avante' },
  --       },
  --       ft = { 'markdown', 'Avante' },
  --     },
  --   },
  -- },

  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'hrsh7th/nvim-cmp', -- Optional: For using slash commands and variables in the chat buffer
      'nvim-telescope/telescope.nvim', -- Optional: For using slash commands
      { 'stevearc/dressing.nvim', opts = {} }, -- Optional: Improves `vim.ui.select`
    },
    keys = {
      { '<leader>aa', ':CodeCompanionActions<cr>', desc = 'Open CodeCompanion Commands', mode = {'n', 'v'} },
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
        },
        inline = {
          adapter = 'openai',
        },
      },
    },
  },
}
