local pack = require("lib.pack")

-- Loaded eagerly on purpose: markview registers its own FileType attachment
-- and upstream advises against lazy-loading, which misses the first markdown
-- buffer. The required parsers (markdown, markdown_inline, html, yaml) come
-- from the treesitter spec.
return {
  src = pack.github("OXY2DEV/markview.nvim"),
  dependencies = pack.github("nvim-tree/nvim-web-devicons"),
  config = function()
    require("markview").setup()
    require("markview.extras.checkboxes").setup()

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function(args)
        vim.keymap.set(
          { "n", "x" },
          "<C-Space>",
          "<cmd>Checkbox toggle<cr>",
          { buffer = args.buf, desc = "Toggle checkbox" }
        )
      end,
    })
  end,
}
