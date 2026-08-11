vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("core")

local pack = require("utils.pack")

pack.setup({
  require("coding"),
  require("review"),
  require("tests"),
  require("style"),
})
