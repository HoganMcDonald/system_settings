-----------------------------------------------------------
-- Treesitter configuration file
-----------------------------------------------------------

-- Plugin: treesitter
-- https://github.com/nvim-treesitter/nvim-treesitter

local present, ts_config = pcall(require, 'nvim-treesitter.configs')

if not present then
  return
end

ts_config.setup({
  ensure_installed = {
    'lua',
    'vim',
    'ruby',
    'vue',
    'javascript',
    'css',
    'html',
    'scss',
  },
  highlight = {
    enable = true,
    use_languagetree = true,
  },
})
