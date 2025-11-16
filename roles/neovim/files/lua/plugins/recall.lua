return {
  {
    'fnune/recall.nvim',
    version = '*',
    config = function()
      local recall = require('recall')

      -- Set up highlight group before initializing recall
      vim.api.nvim_set_hl(0, 'RecallSign', { link = '@comment.note', default = true })

      -- Ensure highlight persists after colorscheme changes
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = '*',
        callback = function()
          vim.api.nvim_set_hl(0, 'RecallSign', { link = '@comment.note', default = false })
        end,
      })

      recall.setup({
        sign = '',
        sign_highlight = 'RecallSign',
        snacks = {
          mappings = {
            unmark_selected_entry = {
              normal = 'dd',
              insert = '<M-d>',
            },
          },
        },
      })
    end,
    keys = {
      {
        '<leader>mm',
        function()
          require('recall').toggle()
        end,
        desc = 'Toggle mark',
      },
      {
        '<leader>mn',
        function()
          require('recall').goto_next()
        end,
        desc = 'Next mark',
      },
      {
        '<leader>mp',
        function()
          require('recall').goto_prev()
        end,
        desc = 'Previous mark',
      },
      {
        '<leader>mc',
        function()
          require('recall').clear()
        end,
        desc = 'Clear all marks',
      },
      {
        '<leader>mo',
        function()
          require('recall.snacks').pick()
        end,
        desc = 'Open marks (Snacks)',
      },
    },
  },
}
