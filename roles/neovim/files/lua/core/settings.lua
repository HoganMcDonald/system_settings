-----------------------------------------------------------
-- Neovim settings
-----------------------------------------------------------

-----------------------------------------------------------
-- Neovim API aliases
-----------------------------------------------------------
--local map = vim.api.nvim_set_keymap  -- set global keymap
local cmd = vim.cmd -- execute Vim commands
local exec = vim.api.nvim_exec -- execute Vimscript
local g = vim.g -- global variables
local opt = vim.opt -- global/buffer/windows-scoped options
local diagnostic = vim.diagnostic
local fn = vim.fn

-----------------------------------------------------------
-- General
-----------------------------------------------------------
g.mapleader = ' ' -- change leader to space
opt.mouse = 'a' -- enable mouse support
opt.clipboard = 'unnamedplus' -- copy/paste to system clipboard
opt.swapfile = false -- don't use swapfile

-----------------------------------------------------------
-- Neovim UI
-----------------------------------------------------------
opt.number = true -- show line number
opt.relativenumber = true -- show line number
opt.showmatch = true -- highlight matching parenthesis
opt.splitright = true -- vertical split to the right
opt.splitbelow = true -- orizontal split to the bottom
opt.ignorecase = true -- ignore case letters when search
opt.smartcase = true -- ignore lowercase for the whole pattern
opt.linebreak = true -- wrap on word boundary
opt.cmdheight = 0 -- hides command bar when not in use

-- remove whitespace on save
cmd([[au BufWritePre * :%s/\s\+$//e]])

-- highlight on yank
exec(
  [[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank{higroup="IncSearch", timeout=700}
  augroup end
]],
  false
)

-----------------------------------------------------------
-- Tabs, indent
-----------------------------------------------------------
opt.expandtab = true -- use spaces instead of tabs
opt.shiftwidth = 2 -- shift 2 spaces when tab
opt.tabstop = 2 -- 1 tab == 2 spaces
opt.softtabstop = 4 -- edit file as if tab stop is 4
opt.smartindent = true -- autoindent new lines
opt.scrolloff = 8 -- scroll screen when within 8 rows of top or bottom
opt.smartindent = true -- indents as smartly as it can

-----------------------------------------------------------
-- Autocompletion
-----------------------------------------------------------
-- insert mode completion options
opt.completeopt = 'menuone,noselect'

-----------------------------------------------------------
-- Colorscheme
-----------------------------------------------------------
opt.termguicolors = true -- enable 24-bit RGB colors

-----------------------------------------------------------
-- Memory, CPU
-----------------------------------------------------------
opt.hidden = true -- enable background buffers
opt.history = 100 -- remember n lines in history
opt.lazyredraw = true -- faster scrolling
opt.synmaxcol = 240 -- max column for syntax highlight

-----------------------------------------------------------
-- Ignores
-----------------------------------------------------------
opt.wildignore = {
  '*.pyc',
  '*_build/*',
  '**/coverage/*',
  '**/node_modules/*',
  '**/android/*',
  '**/ios/*',
  '**/.git/*',
}

-----------------------------------------------------------
-- Startup
-----------------------------------------------------------
-- disable builtins plugins
local disabled_built_ins = {
  'netrw',
  'netrwPlugin',
  'netrwSettings',
  'netrwFileHandlers',
  'gzip',
  'zip',
  'zipPlugin',
  'tar',
  'tarPlugin',
  'getscript',
  'getscriptPlugin',
  'vimball',
  'vimballPlugin',
  '2html_plugin',
  'logipat',
  'rrhelper',
  'spellfile_plugin',
  'matchit',
}

for _, plugin in pairs(disabled_built_ins) do
  g['loaded_' .. plugin] = 1
end

-- disable nvim intro
opt.shortmess:append('sI')

-----------------------------------------------------------
-- Diagnostics
-----------------------------------------------------------
local signs = { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
for type, icon in pairs(signs) do
  local hl = 'DiagnosticSign' .. type
  fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

diagnostic.config({
  virtual_text = false, -- Turn off inline diagnostics
})

-- Use this if you want it to automatically show all diagnostics on the
-- current line in a floating window. Personally, I find this a bit
-- distracting and prefer to manually trigger it (see below). The
-- CursorHold event happens when after `updatetime` milliseconds. The
-- default is 4000 which is much too long
--
-- cmd('autocmd CursorHold * lua vim.lsp.diagnostic.show_line_diagnostics()')
-- o.updatetime = 300
