-----------------------------------------------------------
-- Toggle term configuration file
-----------------------------------------------------------

-- Plugin: toggleterm
-- https://github.com/akinsho/toggleterm.nvim

local present, toggleterm = pcall(require, 'toggleterm')

if not present then
  return
end

local o = vim.o
local api = vim.api
local cmd = vim.cmd

toggleterm.setup({
  size = 20,
  open_mapping = [[«]],
  hide_numbers = true,
  shade_filetypes = {},
  shade_terminals = true,
  shading_factor = 2,
  start_in_insert = true,
  insert_mappings = true,
  persist_size = true,
  direction = 'horizontal',
  close_on_exit = true,
  shell = o.shell,
  float_opts = {
    border = 'curved',
    winblend = 0,
    highlights = {
      border = 'Normal',
      background = 'Normal',
    },
  },
})

function _G.set_terminal_keymaps()
  local opts = { noremap = true }
  api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
  api.nvim_buf_set_keymap(0, 't', 'jk', [[<C-\><C-n>]], opts)
  api.nvim_buf_set_keymap(0, 't', '<C-h>', [[<C-\><C-n><C-W>h]], opts)
  api.nvim_buf_set_keymap(0, 't', '<C-j>', [[<C-\><C-n><C-W>j]], opts)
  api.nvim_buf_set_keymap(0, 't', '<C-k>', [[<C-\><C-n><C-W>k]], opts)
  api.nvim_buf_set_keymap(0, 't', '<C-l>', [[<C-\><C-n><C-W>l]], opts)
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
