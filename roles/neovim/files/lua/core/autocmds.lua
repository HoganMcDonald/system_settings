local cmd = vim.cmd
local api = vim.api

-- Open a file from its last left off position
cmd(
  [[ au BufReadPost * if expand('%:p') !~# '\m/\.git/' && line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif ]]
)

-- Set filetype of jbuilder files
cmd([[ au BufNewFile,BufRead *.json.jbuilder set ft=ruby ]])

-- Close nvim tree if it is the last window
cmd([[ autocmd BufEnter * ++nested if winnr('$') == 1 && bufname() == 'NvimTree_' . tabpagenr() | quit | endif ]])

local autocmds = {
  reload_vimrc = {
    -- Reload vim config automatically
    { 'BufWritePost', [[$VIM_PATH/{*.lua} nested source $MYVIMRC | redraw]] },
  },
  packer = {
    { 'BufWritePost', 'plugins.lua', 'PackerCompile' },
  },
  terminal_job = {
    { 'TermOpen', '*', [[tnoremap <buffer> <Esc> <c-\><c-n>]] },
    { 'TermOpen', '*', 'startinsert' },
    { 'TermOpen', '*', 'setlocal listchars= nonumber norelativenumber' },
  },
  numbertoggle = {
    { 'InsertEnter', '*', 'set number norelativenumber' },
    { 'InsertLeave', '*', 'set number relativenumber' },
  },
}

for group_name, definition in pairs(autocmds) do
  api.nvim_command('augroup ' .. group_name)
  api.nvim_command('autocmd!')
  for _, def in ipairs(definition) do
    local command = table.concat(vim.tbl_flatten({ 'autocmd', def }), ' ')
    api.nvim_command(command)
  end
  api.nvim_command('augroup END')
end
