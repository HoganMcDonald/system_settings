-----------------------------------------------------------
-- Tab line configuration file
-----------------------------------------------------------

-- Plugin: barbar
-- https://github.com/romgrk/barbar.nvim

local present, barbar = pcall(require, 'bufferline')

if not present then
  return
end
