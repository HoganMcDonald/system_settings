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
    'metakirby5/codi.vim'
  },
}
