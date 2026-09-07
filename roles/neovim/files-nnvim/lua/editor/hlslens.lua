local pack = require("lib.pack")

-- Lazy-loaded on its commands and on the first search navigation. `config`
-- wraps the config's existing `n`/`N` expr-mappings with `hlslens.start()`
-- (keeping their `zv` fold-reveal) rather than replacing them, and adds the
-- plugin's `*`/`#`/`g*`/`g#` mappings. `<esc>` already calls `hlslens.stop()`
-- via core/keymaps.
return {
  src = pack.github("kevinhwang91/nvim-hlslens"),
  cmd = { "HlSearchLensToggle", "HlSearchLensEnable", "HlSearchLensDisable" },
  keys = {
    { "n", mode = { "n", "x", "o" }, desc = "Next search result" },
    { "N", mode = { "n", "x", "o" }, desc = "Previous search result" },
    { "*", mode = "n", desc = "Search word forward" },
    { "#", mode = "n", desc = "Search word backward" },
    { "g*", mode = "n", desc = "Search partial word forward" },
    { "g#", mode = "n", desc = "Search partial word backward" },
    -- `/` and `?` have no prior mapping, so they carry an explicit rhs that
    -- just re-executes the key after load (hlslens renders during incsearch
    -- on its own). The search-navigation keys above leave rhs nil so their
    -- `config` maps are what gets re-established after load.
    { "/", "/", mode = "n", desc = "Search forward" },
    { "?", "?", mode = "n", desc = "Search backward" },
  },
  config = function()
    require("hlslens").setup({
      -- Dim the lens once the cursor leaves the matched instances.
      calm_down = true,
    })

    -- The core maps jump with `'Nn'[v:searchforward]` and reveal folds with
    -- `zv`; layering `hlslens.start()` on top keeps both behaviors and adds
    -- the lens. Only the normal-mode maps get `zv`, matching core/keymaps.
    local function lens_jump(key, reveal)
      return function()
        local jump = (key == "n") == (vim.v.searchforward == 1) and "n" or "N"
        if reveal then
          jump = jump .. "zv"
        end
        require("hlslens").start()
        return jump
      end
    end

    vim.keymap.set("n", "n", lens_jump("n", true), { expr = true, desc = "Next search result" })
    vim.keymap.set({ "x", "o" }, "n", lens_jump("n", false), { expr = true, desc = "Next search result" })
    vim.keymap.set("n", "N", lens_jump("N", true), { expr = true, desc = "Previous search result" })
    vim.keymap.set({ "x", "o" }, "N", lens_jump("N", false), { expr = true, desc = "Previous search result" })

    local function lens_word(keys)
      return function()
        require("hlslens").start()
        return keys
      end
    end

    vim.keymap.set("n", "*", lens_word("*"), { expr = true, desc = "Search word forward" })
    vim.keymap.set("n", "#", lens_word("#"), { expr = true, desc = "Search word backward" })
    vim.keymap.set("n", "g*", lens_word("g*"), { expr = true, desc = "Search partial word forward" })
    vim.keymap.set("n", "g#", lens_word("g#"), { expr = true, desc = "Search partial word backward" })
  end,
}
