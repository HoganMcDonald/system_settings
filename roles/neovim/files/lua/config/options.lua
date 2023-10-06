local opt = vim.opt
local o = vim.o

local M = {}

local function map_leader()
  vim.g.mapleader = ' ' -- change leader to space
  vim.g.maplocalleader = ' ' -- change leader to space
end

local function general()
  opt.mouse = 'a' -- enable mouse support
  opt.clipboard = 'unnamedplus' -- copy/paste to system clipboard
  opt.swapfile = false -- don't use swapfile
  opt.shortmess:append('sI') -- disable nvim intro
  -- opt.synmaxcol = 1000 -- max column for syntax highlight

  -- editor
  opt.expandtab = true -- Use spaces instead of tabs
  opt.shiftwidth = 2 -- size of an indent
  opt.tabstop = 2 -- 1 tab == 2 spaces
  opt.scrolloff = 8 -- scroll screen when within 8 rows of top or bottom
  opt.sidescrolloff = 8 -- Columns of context
  opt.laststatus = 3 -- global statusbar
  opt.splitkeep = "screen"
  opt.smartindent = true -- indents as smartly as it can
  opt.splitkeep = 'screen' -- where does the editor split
  opt.completeopt = 'menu,menuone,noselect' -- insert mode completion options
  o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
  o.foldcolumn = '1' -- '0' is not bad
  o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
  o.foldlevelstart = 99
  o.foldenable = true

  -- search
  opt.ignorecase = true -- ignore case letters when search
  opt.smartcase = true -- ignore lowercase for the whole pattern

  -- diagnostics
  local signs = { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
  for type, icon in pairs(signs) do
    local hl = 'DiagnosticSign' .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end

  vim.diagnostic.config({
    virtual_text = false, -- Turn off inline diagnostics
  })
end

local function ui()
  opt.termguicolors = true -- enable 24-bit RGB colors
  opt.number = true -- show line number
  opt.relativenumber = true -- show line number
  opt.showmatch = true -- highlight matching parenthesis
  opt.splitright = true -- vertical split to the right
  opt.splitbelow = true -- horizontal split to the bottom
  opt.linebreak = true -- wrap on word boundary
  opt.wrap = false -- disable line wrap
  opt.cmdheight = 0 -- hides command bar when not in use
end

M.setup = function()
  map_leader()
  general()
  ui()
end

return M
