return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    config = function(_, opts)
      require("codediff").setup(opts)

      local view = require("codediff.ui.view")
      local compact = require("codediff.ui.view.compact")
      local lifecycle = require("codediff.ui.lifecycle")

      local function enable_compact_when_ready(tabpage, attempts)
        attempts = attempts or 20

        vim.defer_fn(function()
          local session = lifecycle.get_session(tabpage)
          if session and session.stored_diff_result then
            compact.enable(tabpage)
            return
          end

          if attempts > 0 then
            enable_compact_when_ready(tabpage, attempts - 1)
          end
        end, 50)
      end

      local create = view.create
      view.create = function(session_config, filetype, on_ready)
        return create(session_config, filetype, function(...)
          enable_compact_when_ready(vim.api.nvim_get_current_tabpage())

          if on_ready then
            on_ready(...)
          end
        end)
      end

      local update = view.update
      view.update = function(tabpage, ...)
        local ok = update(tabpage, ...)
        if ok then
          enable_compact_when_ready(tabpage)
        end
        return ok
      end
    end,
    opts = {
      diff = {
        layout = "side-by-side",
        compact_context_lines = 3,
      },
      explorer = {
        position = "left",
        width = 35,
        view_mode = "tree",
        flatten_dirs = true,
      },
      keymaps = {
        view = {
          toggle_stage = "s",
        },
        explorer = {
          select = "l",
          fold_close = "h",
        },
      },
    },
  },
}
