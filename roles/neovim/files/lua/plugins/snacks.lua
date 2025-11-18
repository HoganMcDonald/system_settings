return {
  {
    'folke/snacks.nvim',
    opts = {},
    keys = {
      -- Disable the default <leader>n notification history keymap
      { '<leader>n', false },
      -- Remap notification history to <leader>sn (search notifications)
      {
        '<leader>sn',
        function()
          require('snacks').notifier.show_history()
        end,
        desc = 'Notification History',
      },
    },
  },
}
