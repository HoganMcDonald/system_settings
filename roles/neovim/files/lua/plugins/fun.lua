return {
  -- ducks
  {
    'tamton-aquib/duck.nvim',
    keys = {
      {
        '<leader>ac',
        function()
          require('duck').hatch('🦀')
        end,
        desc = '🦀'
      },
      {
        '<leader>ak',
        function()
          require('duck').cook()
        end,
        desc = 'kill'
      },
    },
  },

  -- scratchpad
  {
    "LintaoAmons/scratch.nvim",
    keys = {
      {
        '<leader>bn',
        '<cmd>ScratchPad<cr>',
        desc = 'Toggle notes for this buffer',
      },
      {
        '<leader>rn',
        '<cmd>Scratch<cr>',
        desc = 'Create new scratchpad',
      },
    },
  },

  {
    'arjunmahishi/flow.nvim',
    keys = {
      {
        '<leader>rc',
        '<cmd>FlowRunFile<cr>',
        desc = 'Run Code',
      },
      {
        '<leader>rc',
        '<cmd>FlowRunSelected<cr>',
        desc = 'Run Code (selected)',
        mode = 'v'
      },
    },
  }
}
