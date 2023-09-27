-----------------------------------------------------------
-- sidebar configuration file
-----------------------------------------------------------

-- Plugin: sidebar
-- https://github.com/sidebar-nvim/sidebar.nvim

local present, sidebar = pcall(require, 'sidebar-nvim')

if not present then
  return
end

sidebar.setup({
  disable_default_keybindings = 0,
  bindings = nil,
  open = false,
  side = 'right',
  initial_width = 45,
  hide_statusline = true,
  update_interval = 1000,
  sections = { 'datetime', 'git', 'diagnostics' },
  section_separator = { '', '', '' },
  containers = {
    attach_shell = '/bin/sh',
    show_all = true,
    interval = 5000,
  },
  datetime = { format = '%a %b %d, %H:%M', clocks = { { name = 'local' } } },
  todos = { ignored_paths = { '~' } },
  disable_closing_prompt = false,
})
