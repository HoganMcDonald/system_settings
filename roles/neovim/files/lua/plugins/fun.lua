return {
  -- ducks
  {
    'tamton-aquib/duck.nvim',
    keys = {
      {
        '<leader>dd',
        function()
          require('duck').hatch('🦀')
        end,
      },
      {
        '<leader>dk',
        function()
          require('duck').cook()
        end,
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
