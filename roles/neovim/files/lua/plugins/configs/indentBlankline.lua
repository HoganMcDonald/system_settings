-----------------------------------------------------------
-- Blanklines configuration file
-----------------------------------------------------------

-- Plugin: indent-blankline.nvim
-- https://github.com/lukas-reineke/indent-blankline.nvim

local present, blanklines = pcall(require, 'indent_blankline')

if not present then
  return
end

blanklines.setup({
  indentLine_enabled = 1,
  char = '▏',
  buftype_exclude = {
    'nofile',
    'terminal',
    'lsp-installer',
    'lspinfo',
    'TelescopePrompt',
    'TelescopeResults',
    'dashboard',
  },
  filetype_exclude = {
    'help',
    'startify',
    'dashboard',
    'packer',
    'neogitstatus',
    'NvimTree',
    'Trouble',
    'TelescopePrompt',
    'TelescopeResults',
    '',
  },
  show_trailing_blankline_indent = false,
  show_first_indent_level = false,
  show_current_context_start = true,
  use_treesutter = true,
})
