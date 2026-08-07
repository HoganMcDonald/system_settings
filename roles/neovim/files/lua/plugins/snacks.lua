return {
  {
    'folke/snacks.nvim',
    lazy = false,
    priority = 1000,
    opts = {
      picker = {
        actions = {
          trouble_qflist = function(picker)
            require("snacks.picker.actions").qflist(picker)
            vim.schedule(function()
              vim.cmd("cclose")
              require("trouble").open({ mode = "qflist" })
            end)
          end,
        },
        win = {
          input = {
            keys = {
              ["<c-q>"] = { "trouble_qflist", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
              ["<c-q>"] = "trouble_qflist",
            },
          },
        },
      },
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
