vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("core")

local pack = require("lib.pack")

pack.setup({
  require("coding"),
  require("review"),
  require("tests"),
  require("style"),
})
