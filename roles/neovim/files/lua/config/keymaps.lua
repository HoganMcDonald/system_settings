local M = {}

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function setup_general()
  map('n', '<leader>ui', vim.show_pos, { desc = 'Inspect highlight group' })
end

local function setup_movement()
  -- up/down when prefixed with count will not count wrap lines
  map({ 'n', 'x' }, 'j', 'v:count == 0 ? \'gj\' : \'j\'', { expr = true, silent = true })
  map({ 'n', 'x' }, 'k', 'v:count == 0 ? \'gk\' : \'k\'', { expr = true, silent = true })

  -- Resize window using <ctrl> arrow keys
  map('n', '<M-S-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width' })
  map('n', 'Ó', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width' })
  map('n', '<M-S-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease window height' })
  map('n', 'Ô', '<cmd>resize -2<cr>', { desc = 'Decrease window height' })
  map('n', '<M-S-Up>', '<cmd>resize +2<cr>', { desc = 'Increase window height' })
  map('n', '', '<cmd>resize +2<cr>', { desc = 'Increase window height' })
  map('n', '<M-S-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width' })
  map('n', 'Ò', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width' })

  -- window creation
  map('n', '<leader>ws', ':vsp<cr>', { noremap = true, silent = true, desc = 'split' })
  map('n', '<leader>wv', ':sp<cr>', { noremap = true, silent = true, desc = 'vertical split' })
end

local function setup_editor()
  -- Clear search with <esc>
  map({ 'i', 'n' }, '<esc>', '<cmd>noh<cr><esc>', { desc = 'Escape and clear hlsearch' })
  map({ 'n', 'x' }, 'gw', '*N', { desc = 'Search word under cursor' })

  -- highlight selection after adjusting indent
  map('v', '<', '<gv')
  map('v', '>', '>gv')
end

function M.setup()
  setup_movement()
  setup_editor()
  setup_general()
end

return M
