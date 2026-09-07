local pack = require("lib.pack")

return {
  src = pack.github("kylechui/nvim-surround"),
  -- A VersionRange tracks the latest semver tag; the "*" string is treated
  -- as a literal ref by vim.pack and fails to resolve on (re)install.
  version = vim.version.range("*"),
  event = "BufReadPost",
  config = function()
    require("nvim-surround").setup({})
  end,
}
