local pack = require("lib.pack")

-- Lazy-loaded via the `:Chainsaw` command and the `<leader>d*` log keys.
-- `variableLog`/`objectLog` also take a visual selection, so those keys run
-- in both normal and visual mode.
return {
  src = pack.github("chrisgrieser/nvim-chainsaw"),
  cmd = "Chainsaw",
  keys = {
    { "<leader>dv", function() require("chainsaw").variableLog() end, mode = { "n", "x" }, desc = "Variable log" },
    { "<leader>do", function() require("chainsaw").objectLog() end, mode = { "n", "x" }, desc = "Object log" },
    { "<leader>dt", function() require("chainsaw").typeLog() end, mode = { "n", "x" }, desc = "Type log" },
    { "<leader>da", function() require("chainsaw").assertLog() end, mode = { "n", "x" }, desc = "Assert log" },
    { "<leader>de", function() require("chainsaw").emojiLog() end, desc = "Emoji log" },
    { "<leader>dm", function() require("chainsaw").messageLog() end, desc = "Message log" },
    { "<leader>dT", function() require("chainsaw").timeLog() end, desc = "Time log" },
    { "<leader>dd", function() require("chainsaw").debugLog() end, desc = "Debug log" },
    { "<leader>ds", function() require("chainsaw").stacktraceLog() end, desc = "Stacktrace log" },
    { "<leader>dc", function() require("chainsaw").clearLog() end, desc = "Clear console log" },
    { "<leader>dr", function() require("chainsaw").removeLogs() end, mode = { "n", "x" }, desc = "Remove logs" },
  },
  config = function()
    require("chainsaw").setup()
  end,
}
