return {
  {
    'folke/snacks.nvim',
    lazy = false,
    priority = 1000,
    opts = {
      dashboard = {
        preset = {
          header = [[
 ███▄    █ ▓█████  ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓
 ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒
▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░
▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██
▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒
░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░
]],
        },
      },
    },
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
      -- Disable lazygit keybindings (replaced by CodeDiff)
      { '<leader>gg', false },
      { '<leader>gG', false },
      { '<leader>gf', false },
      { '<leader>gl', false },
      { '<leader>gL', false },
      { '<leader>gb', false },
    },
  },
}
