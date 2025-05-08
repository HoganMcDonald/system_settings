return {
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    opts = {},
  },
  {
    'dmmulroy/tsc.nvim',
    cmd = { 'TSC' },
    keys = {
      { '<leader>tc', '<cmd>TSC<cr>', desc = 'TSC' },
      { '<leader>tq', '<cmd>TSCQuickFix<cr>', desc = 'TSC QuickFix' },
    },
    opts = {
      auto_open_qflist = true,
      auto_close_qflist = false,
      auto_focus_qflist = false,
      auto_start_watch_mode = true,

      use_trouble_qflist = true,
      use_diagnostics = true,
      run_as_monorepo = false,
      enable_progress_notifications = true,
      enable_error_notifications = true,
      pretty_errors = true,
    },
  },
}
