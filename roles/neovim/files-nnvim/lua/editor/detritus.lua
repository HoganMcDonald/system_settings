local pack = require("lib.pack")

-- Right-hand panels share one edgy bar, so opening the plan closes the others.
local function close_siblings()
  local edgy = require("lib.edgy")
  edgy.close_filetype("codecompanion")
  edgy.close_filetype("neotest-summary")
end

return {
  src = pack.github("HoganMcDonald/detritus.nvim"),
  cmd = "Detritus",
  keys = {
    {
      "<leader>pp",
      function()
        if not require("detritus").is_open() then
          close_siblings()
        end
        require("detritus").toggle()
      end,
      desc = "Toggle plan",
    },
    {
      "<leader>pb",
      function()
        require("detritus").select_branch()
      end,
      desc = "Plan for branch",
    },
    {
      "<leader>pc",
      function()
        require("detritus").clear()
      end,
      desc = "Clear plan",
    },
    {
      "<leader>pr",
      function()
        require("detritus").refresh()
      end,
      desc = "Refresh plan",
    },
  },
  config = function()
    require("detritus").setup({ layout = "edgy" })
  end,
}
