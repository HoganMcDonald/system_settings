local autocmd = require("lib.autocmd")
local pack = require("lib.pack")

local parsers = {
  "bash",
  "c",
  "css",
  "diff",
  "dockerfile",
  "git_config",
  "git_rebase",
  "gitcommit",
  "gitignore",
  "hcl",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "nix",
  "printf",
  "python",
  "query",
  "regex",
  "ruby",
  "rust",
  "sql",
  "terraform",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

---Buffer-local motions, matching the main config.
---@type table<string, table<string, string>>
local motions = {
  goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
  goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
  goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
  goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
}

---Parsers present on disk. Scanning is a directory walk, so it is cached and
---refreshed only after an install completes.
---@type table<string, true>
local installed = {}

local function refresh_installed()
  installed = {}
  for _, lang in ipairs(require("nvim-treesitter").get_installed("parsers")) do
    installed[lang] = true
  end
end

---@param filetype string
---@return string?
local function language_for(filetype)
  local lang = vim.treesitter.language.get_lang(filetype)
  return (lang and installed[lang]) and lang or nil
end

---@param lang string
---@param query string
---@return boolean
local function has_query(lang, query)
  local ok, result = pcall(vim.treesitter.query.get, lang, query)
  return ok and result ~= nil
end

---@param buf integer
local function attach_motions(buf)
  local lang = language_for(vim.bo[buf].filetype)
  if not lang or not has_query(lang, "textobjects") then
    return
  end

  for method, keymaps in pairs(motions) do
    for lhs, query in pairs(keymaps) do
      local name = query:gsub("@", ""):gsub("%..*", "")
      local direction = lhs:sub(1, 1) == "[" and "Previous " or "Next "
      local edge = lhs:sub(2, 2):match("%u") and " end" or " start"

      vim.keymap.set({ "n", "x", "o" }, lhs, function()
        -- `[c`/`]c` stay on their builtin diff meaning inside a diff view.
        if vim.wo.diff and lhs:find("[cC]") then
          return vim.cmd("normal! " .. lhs)
        end
        require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
      end, {
        buffer = buf,
        desc = direction .. name .. edge,
        silent = true,
      })
    end
  end
end

-- Loaded eagerly: highlighting is driven by a FileType autocmd, which has to be
-- registered before the first buffer is read.
return {
  {
    src = pack.github("nvim-treesitter/nvim-treesitter"),
    version = "main",
    config = function()
      require("nvim-treesitter").setup()
      refresh_installed()

      local missing = vim.tbl_filter(function(lang)
        return not installed[lang]
      end, parsers)

      if #missing > 0 then
        local install = require("nvim-treesitter").install(missing)
        if type(install) == "table" and type(install.await) == "function" then
          install:await(refresh_installed)
        end
      end

      autocmd.create({
        event = autocmd.event("FileType"),
        group = vim.api.nvim_create_augroup("Nvim_treesitter", { clear = true }),
        callback = function(args)
          local lang = language_for(args.match)
          if not lang then
            return
          end

          if has_query(lang, "highlights") then
            pcall(vim.treesitter.start, args.buf)
          end

          if has_query(lang, "indents") then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  {
    src = pack.github("nvim-treesitter/nvim-treesitter-textobjects"),
    version = "main",
    dependencies = pack.github("nvim-treesitter/nvim-treesitter"),
    config = function()
      require("nvim-treesitter-textobjects").setup({
        move = { set_jumps = true },
      })

      autocmd.create({
        event = autocmd.event("FileType"),
        group = vim.api.nvim_create_augroup("Nvim_treesitter_textobjects", { clear = true }),
        callback = function(args)
          attach_motions(args.buf)
        end,
      })

      vim.tbl_map(attach_motions, vim.api.nvim_list_bufs())
    end,
  },

  {
    src = pack.github("nvim-treesitter/nvim-treesitter-context"),
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("treesitter-context").setup({
        max_lines = 3,
        multiline_threshold = 1,
      })
    end,
  },

  {
    src = pack.github("windwp/nvim-ts-autotag"),
    -- Only relevant while typing tags.
    event = "InsertEnter",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },

  {
    src = pack.github("sustech-data/wildfire.nvim"),
    dependencies = pack.github("nvim-treesitter/nvim-treesitter"),
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("wildfire").setup()
    end,
  },
}
