-----------------------------------------------------------
-- Scrollbar configuration file
-----------------------------------------------------------

-- Plugin: scrollbar
-- https://github.com/petertriho/nvim-scrollbar

local present, scrollbar = pcall(require, 'scrollbar')

if not present then
  return
end

local colors = require('core.colors').get()

scrollbar.setup({
  show = true,
  handle = {
    text = ' ',
    color = colors.grey,
    hide_if_all_visible = true, -- Hides handle if all lines are visible
  },
  marks = {
    Search = { text = { '-', '=' }, priority = 0, color = colors.orange },
    Error = { text = { '-', '=' }, priority = 1, color = colors.red },
    Warn = { text = { '-', '=' }, priority = 2, color = colors.gold },
    Info = { text = { '-', '=' }, priority = 3, color = colors.blue },
    Hint = { text = { '-', '=' }, priority = 4, color = colors.green },
    Misc = { text = { '-', '=' }, priority = 5, color = colors.lavender },
  },
  excluded_filetypes = {
    '',
    'prompt',
    'TelescopePrompt',
  },
  autocmd = {
    render = {
      'BufWinEnter',
      'TabEnter',
      'TermEnter',
      'WinEnter',
      'CmdwinLeave',
      'TextChanged',
      'VimResized',
      'WinScrolled',
    },
  },
  handlers = {
    diagnostic = true,
    search = false, -- Requires hlslens to be loaded
  },
})
