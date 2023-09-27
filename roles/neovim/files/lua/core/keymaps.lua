local map = vim.api.nvim_set_keymap
local api = vim.api
local default_opts = { noremap = true, silent = true }

-- window navigation
-- this exposes a function to be used by skhd. If skhd isn't running, below keymaps will work as usual
api.nvim_exec([[
  function! NvimYabaiNavigate(yabai_direction, vim_direction)
    let win_nr_before = winnr()
    execute("wincmd " . a:vim_direction)
    if win_nr_before ==# winnr()
      call system("yabai -m window --focus " . a:yabai_direction)
    endif
  endfunction
]], false)

-- windows
map('n', '<leader>ws', ':vsp<cr>', default_opts)
map('n', '<leader>wv', ':sp<cr>', default_opts)
map('n', '∆', '<C-W><C-J>', default_opts)
map('n', '˚', '<C-W><C-K>', default_opts)
map('n', '¬', '<C-W><C-L>', default_opts)
map('n', '˙', '<C-W><C-H>', default_opts)
map('n', '<M-Left>', ':vertical resize -1<cr>', default_opts)
map('n', '<M-Right>', ':vertical resize +1<cr>', default_opts)
map('n', '<M-Down>', ':resize -1<cr>', default_opts)
map('n', '<M-Up>', ':resize +1<cr>', default_opts)

-- terminal
map('t', '<Esc>', '<C-\\><C-n>', default_opts)

-- diagnostic
map('n', '<leader>d', ':lua vim.diagnostic.open_float()<cr>', default_opts)
map('n', '<leader>n', ':lua vim.diagnostic.goto_next()<cr>', default_opts)
map('n', '<leader>p', ':lua vim.diagnostic.goto_prev()<cr>', default_opts)

-- format
map('n', '<leader>bf', ':lua vim.lsp.buf.format { async = true }<cr>', default_opts)
