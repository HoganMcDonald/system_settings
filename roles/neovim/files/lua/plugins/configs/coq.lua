-----------------------------------------------------------
-- Coq configuration file
-----------------------------------------------------------

-- Plugin: coq
-- https://github.com/ms-jpq/coq_nvim

local g = vim.g
local cmd = vim.cmd

g.coq_settings = {
  auto_start = 'shut-up',
}

local present, coq = pcall(require, 'coq')

if not present then
  return
end

cmd('COQnow --shut-up')
