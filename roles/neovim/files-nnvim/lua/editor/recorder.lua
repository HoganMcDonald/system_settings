local pack = require("lib.pack")

-- Loaded eagerly: it owns `q` and `Q`, and a lazy `keys` trigger would swallow
-- the first press of `q` while the plugin loads instead of starting a recording.
return {
  src = pack.github("chrisgrieser/nvim-recorder"),
  config = function()
    require("recorder").setup({
      -- Macros rotate through these registers; `^` switches the active slot.
      slots = { "a", "b", "c" },
      -- q: start/stop recording, Q: play, <C-q>: switch slot, cq: edit,
      -- dq: delete all, yq: yank, ##: add a breakpoint while recording.
      mapping = {
        startStopRecording = "q",
        playMacro = "Q",
        switchSlot = "<C-q>",
        editMacro = "cq",
        deleteAllMacros = "dq",
        yankMacro = "yq",
        addBreakPoint = "##",
      },
      -- noice routes `vim.notify`, and the lualine component shows the state.
      lessNotifications = true,
      useNerdfontIcons = true,
      performanceOpts = {
        countThreshold = 100,
        lazyredraw = true,
        noSystemClipboard = true,
        autocmdEventsIgnore = { "TextChanged", "TextChangedI", "InsertLeave", "InsertEnter" },
      },
    })
  end,
}
