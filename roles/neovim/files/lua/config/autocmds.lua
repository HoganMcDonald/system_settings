-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Ensure code action keymap is always bound on LspAttach, without a capability check.
-- LazyVim's default <leader>ca uses `has="codeAction"` which is evaluated at attach time.
-- Servers like vtsls register textDocument/codeAction *dynamically* (after LspAttach),
-- so the capability check fails → keymap is silently dropped. After a crash/restart,
-- LspDetach clears snacks' tracking state and LspAttach re-runs the check — which fails
-- again, leaving the keymap permanently unbound for that session.
-- Setting it here unconditionally (buffer-local) overrides snacks' conditional binding.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_stable_keymaps", { clear = true }),
  callback = function(args)
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {
      buffer = args.buf,
      desc = "Code Action",
    })
  end,
})

-- Detach LSP clients from non-file buffers (e.g. diffview://) to prevent crashes
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("detach_lsp_from_non_file", { clear = true }),
  callback = function(args)
    local uri = vim.uri_from_bufnr(args.buf)
    if uri and not uri:match("^file://") then
      vim.defer_fn(function()
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
          vim.lsp.buf_detach_client(args.buf, client.id)
        end
      end, 0)
    end
  end,
})
