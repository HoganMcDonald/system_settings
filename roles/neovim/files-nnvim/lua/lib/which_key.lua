local M = {}

---which-key keeps its leader trigger as a buffer-local mapping, and rebuilds it
---from a 50ms poll keyed on the last buffer it saw entered. It also drops that
---mapping on `LspAttach`/`LspDetach`, which a language server fires several
---times per file.
---
---A sidebar adopted into the layout is entered without the cursor moving, so
---that bookkeeping is left pointing at the sidebar buffer while the cursor sits
---elsewhere. The poll then short-circuits forever, and the next LSP event
---removes the leader trigger from the real buffer for good.
---
---Re-announcing the buffer the cursor is actually in repairs the poll, which is
---what makes which-key self-heal from every later clear.
function M.resync()
  vim.api.nvim_exec_autocmds("BufEnter", { buffer = vim.api.nvim_get_current_buf() })
end

return M
