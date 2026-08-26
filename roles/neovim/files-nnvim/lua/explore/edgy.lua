local pack = require("lib.pack")

---Match a neo-tree window by the source it is displaying.
---@param source string
---@return fun(buf: integer): boolean
local function neo_tree_source(source)
  return function(buf)
    return vim.b[buf].neo_tree_source == source
  end
end

local function filesystem_open()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.b[vim.api.nvim_win_get_buf(win)].neo_tree_source == "filesystem" then
      return true
    end
  end
  return false
end

return {
  src = pack.github("folke/edgy.nvim"),
  config = function()
    require("edgy").setup({
      animate = { enabled = false },
      options = {
        left = { size = 40 },
        right = { size = 70 },
      },
      -- The right edgebar hosts the AI chat, which opens as a vertical split.
      right = {
        {
          title = "CodeCompanion",
          ft = "codecompanion",
        },
        {
          title = "Tests",
          ft = "neotest-summary",
        },
      },
      wo = {
        -- Separators are mapped to their own group so the colorscheme can blend
        -- them into the sidebar background.
        winhighlight = table.concat({
          "Normal:EdgyNormal",
          "WinBar:EdgyWinBar",
          "WinBarNC:EdgyWinBarNC",
          "WinSeparator:EdgySeparator",
        }, ","),
      },
      left = {
        {
          title = "Files",
          ft = "neo-tree",
          filter = neo_tree_source("filesystem"),
          open = "Neotree position=left filesystem",
          pinned = true,
          size = { height = 0.5 },
        },
        {
          title = "Git Status",
          ft = "neo-tree",
          filter = neo_tree_source("git_status"),
          -- Opened at another position so neo-tree creates a dedicated window
          -- that edgy then relocates into this sidebar slot.
          open = "Neotree show position=right git_status",
          pinned = true,
          size = { height = 0.25 },
        },
        {
          title = "Outline",
          ft = "Outline",
          open = "OutlineOpen",
          pinned = true,
          size = { height = 0.25 },
        },
      },
    })

    vim.keymap.set("n", "<leader>e", function()
      local edgy = require("edgy")
      if filesystem_open() then
        edgy.close("left")
      else
        edgy.open("left")
        vim.schedule(function()
          vim.cmd("Neotree focus position=left filesystem")
        end)
      end
    end, { desc = "Explorer sidebar" })
  end,
}
