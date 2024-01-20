local M = {}

local concat = require('util.concat')

local options = {}

-- order listed is the order they are concatenated
local groups = {
  'util',
  'colorscheme',
  'core',
  'lsp',
  'dap',
  'editor',
  'git',
  'treesitter',
  'coding',
  'ui',
  'fun',
}

local function ensure_installed()
  local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      'git',
      'clone',
      '--filter=blob:none',
      'https://github.com/folke/lazy.nvim.git',
      '--branch=stable', -- latest stable release
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)
end

local function init(spec)
  require('lazy').setup(spec, options)
end

function M.setup()
  ensure_installed()

  local spec = {}
  for _, group_name in pairs(groups) do
    local group = require('plugins.' .. group_name)
    spec = concat(spec, group)
  end

  init(spec)
end

return M
