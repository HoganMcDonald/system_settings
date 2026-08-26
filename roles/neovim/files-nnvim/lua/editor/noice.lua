local pack = require("lib.pack")

return {
  src = pack.github("folke/noice.nvim"),
  dependencies = pack.github("MunifTanjim/nui.nvim"),
  event = "VimEnter",
  keys = {
    { "<leader>sn", "<cmd>Noice history<cr>", desc = "Notification history" },
    { "<leader>nl", "<cmd>Noice last<cr>", desc = "Last notification" },
  },
  config = function()
    require("noice").setup({
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
        lsp_doc_border = true,
      },
    })
  end,
}
