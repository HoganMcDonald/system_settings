local types = require("lib.types")

local M = {}

---@alias NvimAutocmdEvent NvimBrand<string, "autocmd-event">

local event, unwrap_event = types.create_brand("autocmd-event", types.is_string)

---@param name string
---@return NvimAutocmdEvent
---@example autocmd.event("BufWritePre")
function M.event(name)
  assert(type(name) == "string" and name ~= "", "autocmd event must be a non-empty string")
  return event(name)
end

---@param value NvimAutocmdEvent|NvimAutocmdEvent[]
---@return string|string[]
local function unwrap_events(value)
  if type(value) == "table" and value._brand == "autocmd-event" then
    return unwrap_event(value)
  end

  assert(type(value) == "table", "autocmd event must be a branded event or list of branded events")
  return vim.tbl_map(unwrap_event, value)
end

---@class NvimAutocmdSpec: vim.api.keyset.create_autocmd
---@field event NvimAutocmdEvent|NvimAutocmdEvent[]

---@param definition NvimAutocmdSpec
---@param opts? { group: integer|string, before: fun(args: vim.api.keyset.create_autocmd.callback_args)? }
---@return integer
function M.create(definition, opts)
  vim.validate("definition", definition, "table")

  local autocmd_opts = vim.deepcopy(definition)
  local events = unwrap_events(autocmd_opts.event)
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

  return vim.api.nvim_create_autocmd(events, autocmd_opts)
end

---@param spec NvimPackSpec
---@param name string
---@param before? fun(args: vim.api.keyset.create_autocmd.callback_args)
function M.from_spec(spec, name, before)
  if not spec.autocmds then
    return
  end

  local group = vim.api.nvim_create_augroup("NvimPlugin_" .. name:gsub("[^%w_]", "_"), { clear = true })

  for _, definition in ipairs(spec.autocmds) do
    M.create(definition, { group = group, before = before })
  end
end

return M
