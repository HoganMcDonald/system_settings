return {
  -- Patch client/registerCapability to re-trigger LspAttach after dynamic capability
  -- registration. Some servers (e.g. vtsls) advertise capabilities like codeAction,
  -- rename, and inlayHints *after* the initial handshake. LazyVim's snacks-backed
  -- keymaps use capability filters that are evaluated at LspAttach time — if the
  -- capability isn't registered yet, the keymap is skipped and never retried.
  --
  -- This patch fires LspAttach again for all attached buffers whenever the server
  -- registers new capabilities, giving snacks a second chance to evaluate its filters.
  -- snacks' internal dedup (done table) was already cleared by the preceding LspDetach
  -- on crash, so re-firing after restart works correctly.
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "b0o/SchemaStore.nvim",
    },
    init = function()
      local orig = vim.lsp.handlers["client/registerCapability"]
      vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
        local result = orig(err, res, ctx)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if client then
          for bufnr in pairs(client.attached_buffers) do
            vim.api.nvim_exec_autocmds("LspAttach", {
              buffer = bufnr,
              data = { client_id = client.id },
            })
          end
        end
        return result
      end
    end,
    opts = function(_, opts)
      local schemastore = require("schemastore")

      opts.servers = opts.servers or {}
      opts.servers.jsonls = vim.tbl_deep_extend("force", opts.servers.jsonls or {}, {
        settings = {
          json = {
            schemas = schemastore.json.schemas(),
            validate = { enable = true },
          },
        },
      })
      opts.servers.yamlls = vim.tbl_deep_extend("force", opts.servers.yamlls or {}, {
        settings = {
          yaml = {
            schemaStore = {
              -- You must disable built-in schemaStore support if you want to use
              -- this plugin and its advanced options like `ignore`.
              enable = false,
              -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
              url = "",
            },
            schemas = schemastore.yaml.schemas(),
          },
        },
      })
    end,
  },
}
