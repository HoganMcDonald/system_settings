return {
  {
    'backdround/global-note.nvim',
    config = function()
      local global_note = require('global-note')

      global_note.setup({
        -- Filename to use for default note
        filename = 'global.md',

        -- Directory to keep default note
        directory = vim.fn.stdpath('data') .. '/global-note/',

        -- Floating window title
        title = 'Global Note',

        -- Window configuration
        window_config = function()
          local window_height = vim.api.nvim_list_uis()[1].height
          local window_width = vim.api.nvim_list_uis()[1].width
          return {
            relative = 'editor',
            border = 'rounded',
            title = 'Global Note',
            title_pos = 'center',
            width = math.floor(0.7 * window_width),
            height = math.floor(0.85 * window_height),
            row = math.floor(0.05 * window_height),
            col = math.floor(0.15 * window_width),
          }
        end,

        -- Autosave on window close
        autosave = true,
      })
    end,
    keys = {
      {
        '<leader>gn',
        function()
          require('global-note').toggle_note()
        end,
        desc = 'Toggle global note',
      },
    },
  },
}
