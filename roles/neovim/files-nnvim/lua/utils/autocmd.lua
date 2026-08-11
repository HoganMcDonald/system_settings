local M = {}

---@class NnvimAutocmdSpec: vim.api.keyset.create_autocmd
---@field event string|string[]

---@param definition NnvimAutocmdSpec
---@param opts? { group: integer|string, before: fun(args: vim.api.keyset.create_autocmd.callback_args)? }
---@return integer
function M.create(definition, opts)
  vim.validate("definition", definition, "table")
  vim.validate("definition.event", definition.event, { "string", "table" })

  local autocmd_opts = vim.deepcopy(definition)
  local event = autocmd_opts.event
  local callback = autocmd_opts.callback
  local command = autocmd_opts.command
  autocmd_opts.event = nil

  if opts and opts.group then
    autocmd_opts.group = opts.group
  end

  if opts and opts.before then
    autocmd_opts.command = nil
    autocmd_opts.callback = function(args)
      opts.before(args)

      if callback then
        return callback(args)
      end

      if command then
        vim.cmd(command)
      end
    end
  end

  return vim.api.nvim_create_autocmd(event, autocmd_opts)
end

---@param spec NnvimPackSpec
---@param before? fun(args: vim.api.keyset.create_autocmd.callback_args)
function M.from_spec(spec, before)
  if not spec.autocmds then
    return
  end

  local source = spec.src:gsub("/+$", "")
  source = source:gsub("%.git$", "")
  local name = spec.name or vim.fs.basename(source)
  local group = vim.api.nvim_create_augroup("NnvimPlugin_" .. name:gsub("[^%w_]", "_"), { clear = true })

  for _, definition in ipairs(spec.autocmds) do
    M.create(definition, { group = group, before = before })
  end
end

return M
