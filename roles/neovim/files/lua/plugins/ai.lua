return {
  -- CodeCompanion
  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'hrsh7th/nvim-cmp', -- Optional: For using slash commands and variables in the chat buffer
      'nvim-telescope/telescope.nvim', -- Optional: For using slash commands
      'banjo/contextfiles.nvim', -- cursor rules integration
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
      { '<leader>ac', ':CodeCompanionActions<cr>', desc = 'Open CodeCompanion Commands', mode = { 'n', 'v' } },
    },
    config = {
      adapters = {
        anthropic = function()
          return require('codecompanion.adapters').extend('anthropic', {
            schema = {
              model = {
                default = 'claude-3-7-sonnet-latest',
              },
            },
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
      prompt_library = {
        ['Plan Project'] = {
          strategy = 'chat',
          description = 'Plans out steps to execute a project based on a ticket',
          prompts = {
            {
              role = 'system',
              content = function(context)
                local ctx = require 'contextfiles.extensions.codecompanion'

                local contextfiles = ctx.get(context.filename, {
                  root_markers = { '.git' },
                  rules_dir = '.cursor/rules',
                })

                return [[
                  You are CodeCompanion, an expert programming assistant tasked with creating detailed project implementation plans.

## CONTEXT
                  You are analyzing a programming project based on a ticket or project description provided by the user. You have access to relevant files from the codebase through the contextfiles feature, and you can use MCP server tools to gather more information.

## YOUR TASK
                  1. Carefully read and understand the ticket/project description provided by the user.
                  2. Analyze the contextfiles information below to understand the current state of the codebase.
                  3. Use @mcp server tools when necessary to:
                     - also make use of @files and @cmd_runner
                     - Search for relevant files or code snippets
                     - Understand project structure
                     - Identify potential dependencies or conflicts
                  4. Create a comprehensive implementation plan that includes:
                     - A high-level overview of the required changes
                     - Specific files that need modification (existing or new)
                     - Detailed step-by-step tasks with specific code areas to modify
                     - Potential challenges or edge cases to consider
                     - Testing strategy suggestions
                     - Estimated complexity and effort required
                  5. Confirm the plan with the user
                     - offer a TLDR section at the bottom of your response
                     - number each larger step you reasoned about
                     - ask user if they want to remove/add steps
                     - ask user if they want to edit any step
                     - continue asking until user confirms all steps are what they want
                  6. Generate a prompt the user can paste into an agent workflow to build the feature
                     - should include the steps that have been confirmed
                     - should be informed by available context
                     - should include specifics when possible

                  ## RESPONSE FORMAT
                    Structure your response as follows:

                    ### Ticket Analysis 🎫
                    Summarize your understanding of the ticket/project requirements.

                    ### Codebase Assessment 🔍
                    Analyze the current state of the codebase based on contextfiles and MCP tool insights.

                    ### Implementation Plan 📝
                    Provide a detailed, step-by-step plan for implementing the requested changes.

                    ### Technical Considerations ⚠️
                    Highlight important technical aspects, potential challenges, and edge cases.

                    ### Next Steps 👣
                    Suggest immediate next actions the developer should take.

                    ### TLDR Summary 📌
                    1. ✅ [First major step]
                    2. ✅ [Second major step]
                    3. ✅ [Third major step]
                    ...

                    ❓ Would you like to add, remove, or modify any steps in this plan?

                    ### Implementation Prompt 🤖
                    ```
                    [Ready-to-use prompt for the agent workflow will be placed here]
                    ```

                    Use the contextfiles information provided below to inform your analysis:

                    ]] .. contextfiles
              end,
            },
            {
              role = 'user',
              content = function(context)
                local ctx = require 'contextfiles.extensions.codecompanion'

                local contextfiles = ctx.get(context.filename, {
                  root_markers = { '.git' },
                  rules_dir = '.cursor/rules',
                })
                return '@mcp @cmd_runner\n\nEvaluate the following ticket:\n\n' .. contextfiles
              end,
            },
          },
        },
      },
    },
  },

  {
    'greggh/claude-code.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim', -- Required for git operations
    },
    keys = {
      {
        '<leader>aa',
        '<cmd>ClaudeCode<CR>',
        desc = 'Open Claude Code workflow',
        mode = { 'n', 'v' },
      },
    },
    config = function()
      require('claude-code').setup()
    end,
  },

  -- Copilot
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    build = ':Copilot auth',
    event = 'BufReadPost',
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
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

  {
    'HoganMcDonald/pointer.nvim',
    dev = true,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
    keys = {
      {
        '<leader>at',
        function()
          require('pointer').toggle_sidepanel()
        end,
        desc = 'Toggle pointer',
      },
    },
    opts = {},
    config = function(_, opts)
      require('pointer').setup(opts)
    end,
  },
}
