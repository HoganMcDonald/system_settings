local pack = require("lib.pack")

---Servers to install through mason and enable. Keys are `lspconfig` names, so
---they double as mason-lspconfig's install list. Values extend the defaults
---that `nvim-lspconfig` ships in its `lsp/` directory.
---@type table<string, vim.lsp.Config>
local server_settings = {
  bashls = {},
  docker_compose_language_service = {},
  dockerls = {},
  eslint = {},
  jsonls = {},
  marksman = {},
  nil_ls = {},
  pyright = {},
  ruff = {},
  tailwindcss = {},
  taplo = {},
  terraformls = {},
  yamlls = {},
  lua_ls = {
    settings = {
      Lua = {
        codeLens = { enable = true },
        diagnostics = {
          globals = { "vim" },
          -- Plugin annotations mark optional option fields as required, so
          -- partial `setup` calls would otherwise warn.
          disable = { "missing-fields" },
        },
        hint = { enable = true },
        workspace = { checkThirdParty = false },
      },
    },
  },
}

---Servers enabled without mason-lspconfig installing them. `tsc` supersedes the
---deprecated `tsgo` server, resolves its binary from `node_modules/.bin` or
---PATH, and skips attaching when no candidate supports `--lsp`. The `tsgo` tool
---below provides that binary.
---@type table<string, vim.lsp.Config>
local unmanaged_servers = {
  tsc = {},
}

---Tools that are not installed as a side effect of the server list.
local tools = { "prettier", "shfmt", "sqlfluff", "stylua", "tsgo" }

local prettier_filetypes = {
  "css",
  "graphql",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "markdown",
  "scss",
  "typescript",
  "typescriptreact",
  "yaml",
}

local formatters_by_ft = {
  bash = { "shfmt" },
  hcl = { "terraform_fmt" },
  lua = { "stylua" },
  python = { "ruff_organize_imports", "ruff_format" },
  sh = { "shfmt" },
  sql = { "sqlfluff" },
  terraform = { "terraform_fmt" },
  toml = { "taplo" },
  zsh = { "shfmt" },
}

for _, filetype in ipairs(prettier_filetypes) do
  formatters_by_ft[filetype] = { "prettier" }
end

return {
  -- Provides the default server definitions that `vim.lsp.config` reads from
  -- the runtime path. Loaded eagerly so servers are registered before the first
  -- buffer is read.
  {
    src = pack.github("neovim/nvim-lspconfig"),
    dependencies = {
      pack.github("b0o/SchemaStore.nvim"),
      -- Ordered before this spec so mason has prepended its bin directory to
      -- PATH before any server resolves its executable.
      pack.github("mason-org/mason.nvim"),
    },
    config = function()
      local schemastore = require("schemastore")
      local configs = vim.deepcopy(server_settings)

      configs.jsonls = vim.tbl_deep_extend("force", configs.jsonls, {
        settings = {
          json = {
            schemas = schemastore.json.schemas(),
            validate = { enable = true },
          },
        },
      })

      configs.yamlls = vim.tbl_deep_extend("force", configs.yamlls, {
        settings = {
          yaml = {
            -- The built-in store has to be off for SchemaStore.nvim's richer
            -- options to take effect.
            schemaStore = { enable = false, url = "" },
            schemas = schemastore.yaml.schemas(),
          },
        },
      })

      for name, config in pairs(vim.tbl_extend("error", configs, unmanaged_servers)) do
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end
    end,
  },

  {
    src = pack.github("mason-org/mason.nvim"),
    config = function()
      require("mason").setup()

      local registry = require("mason-registry")
      registry.refresh(function()
        for _, name in ipairs(tools) do
          local ok, package = pcall(registry.get_package, name)
          if ok and not package:is_installed() then
            package:install()
          end
        end
      end)
    end,
  },

  {
    src = pack.github("mason-org/mason-lspconfig.nvim"),
    dependencies = {
      pack.github("mason-org/mason.nvim"),
      pack.github("neovim/nvim-lspconfig"),
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(server_settings),
        -- Servers are enabled above, with their settings attached.
        automatic_enable = false,
      })
    end,
  },

  -- Lua language server support for the Neovim API and plugin sources.
  {
    src = pack.github("folke/lazydev.nvim"),
    config = function()
      require("lazydev").setup({
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      })
    end,
  },

  {
    src = pack.github("stevearc/conform.nvim"),
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = formatters_by_ft,
        default_format_opts = { lsp_format = "fallback" },
        format_on_save = function(buf)
          if vim.g.autoformat == false or vim.b[buf].autoformat == false then
            return nil
          end

          return { timeout_ms = 3000, lsp_format = "fallback" }
        end,
      })

      -- Takes over `<leader>cf` from core, so formatters run before the LSP.
      vim.keymap.set({ "n", "x" }, "<leader>cf", function()
        conform.format({ async = true, lsp_format = "fallback" })
      end, { desc = "Format" })
    end,
  },

  {
    src = pack.github("dnlhc/glance.nvim"),
    event = "LspAttach",
    config = function()
      local glance = require("glance")

      glance.setup({
        height = 18,
        zindex = 45,
        border = { enable = true, top_char = "─", bottom_char = "─" },
        list = { position = "right", width = 0.33 },
        preview_win_opts = { cursorline = true, number = true, wrap = true },
        theme = { enable = true, mode = "auto" },
        winbar = { enable = true },
      })

      local pickers = {
        gD = "definitions",
        gR = "references",
        gY = "type_definitions",
        gI = "implementations",
      }

      for lhs, picker in pairs(pickers) do
        vim.keymap.set("n", lhs, "<cmd>Glance " .. picker .. "<cr>", { desc = "Glance " .. picker })
      end
    end,
  },

  {
    src = pack.github("RRethy/vim-illuminate"),
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("illuminate").configure({
        delay = 0,
        large_file_cutoff = 2000,
        large_file_overrides = { providers = { "lsp" } },
      })

      ---@param lhs string
      ---@param direction string
      ---@param buf? integer
      local function map(lhs, direction, buf)
        vim.keymap.set("n", lhs, function()
          require("illuminate")["goto_" .. direction .. "_reference"](false)
        end, {
          buffer = buf,
          desc = direction == "next" and "Next reference" or "Previous reference",
        })
      end

      map("]]", "next")
      map("[[", "prev")

      -- Re-applied per buffer because many ftplugins claim `[[` and `]]`.
      require("lib.autocmd").create({
        event = require("lib.autocmd").event("FileType"),
        group = vim.api.nvim_create_augroup("Nvim_illuminate", { clear = true }),
        callback = function(args)
          map("]]", "next", args.buf)
          map("[[", "prev", args.buf)
        end,
      })
    end,
  },

  {
    src = pack.github("smjonas/inc-rename.nvim"),
    config = function()
      require("inc_rename").setup({})

      vim.keymap.set("n", "<leader>cr", function()
        return ":IncRename " .. vim.fn.expand("<cword>")
      end, { expr = true, desc = "Rename" })
    end,
  },

  {
    src = pack.github("folke/trouble.nvim"),
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols" },
    },
    config = function()
      require("trouble").setup()
    end,
  },
}
