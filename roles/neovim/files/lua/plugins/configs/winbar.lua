-----------------------------------------------------------
-- Winbar configuration file
-----------------------------------------------------------

-- Plugin: winbar
-- https://github.com/fgheng/winbar.nvim

local present, winbar = pcall(require, 'winbar')

if not present then
  return
end

winbar.setup {
  enabled = true,

  show_file_path = true,
  show_symbols = true,

  colors = {
    path = '',
    file_name = '',
    symbols = '',
  },

  icons = {
    file_icon_default = '',
    seperator = '>',
    editor_state = '●',
    lock_icon = '',
  },

  exclude_filetype = {
    'help',
    'startify',
    'dashboard',
    'packer',
    'neogitstatus',
    'NvimTree',
    'Trouble',
    'alpha',
    'lir',
    'Outline',
    'spectre_panel',
    'toggleterm',
    'qf',
  }
}
