local autocmd = require("utils.autocmd")

local M = {}

---@class NnvimPackCommand
---@field name string
---@field opts? vim.api.keyset.user_command

---@class NnvimPackEvent
---@field event string|string[]
---@field pattern? string|string[]

---@class NnvimPackKeymap: vim.keymap.set.Opts
---@field [1] string Left-hand side of the mapping
---@field [2]? string|function Right-hand side to install after loading
---@field mode? string|string[]

---@class NnvimPackSpec: vim.pack.Spec
---@field init? fun(spec: NnvimPackSpec)
---@field config? fun(spec: NnvimPackSpec)
---@field cmd? string|NnvimPackCommand|(string|NnvimPackCommand)[]
---@field event? string|NnvimPackEvent|(string|NnvimPackEvent)[]
---@field keys? NnvimPackKeymap[]
---@field autocmds? NnvimAutocmdSpec[]

local function is_spec(value)
  return type(value) == "string" or (type(value) == "table" and type(value.src) == "string")
end

---@param ... NnvimPackSpec|string|(NnvimPackSpec|string)[]
---@return (NnvimPackSpec|string)[]
function M.flatten(...)
  local flattened = {}

  local function visit(value)
    if value == nil then
      return
    end

    if is_spec(value) then
      table.insert(flattened, value)
      return
    end

    if type(value) ~= "table" then
      error("invalid plugin spec: " .. vim.inspect(value))
    end

    for _, item in ipairs(value) do
      visit(item)
    end
  end

  for index = 1, select("#", ...) do
    visit(select(index, ...))
  end

  return flattened
end

---@param module string
---@return (NnvimPackSpec|string)[]
function M.collect(module)
  local module_path = module:gsub("%.", "/")
  local directory = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", module_path)
  local paths = vim.fn.globpath(directory, "*.lua", false, true)
  table.sort(paths)

  local specs = {}
  for _, path in ipairs(paths) do
    local name = vim.fs.basename(path):gsub("%.lua$", "")
    if name ~= "init" then
      table.insert(specs, require(module .. "." .. name))
    end
  end

  return M.flatten(specs)
end

---@param spec NnvimPackSpec
---@return string
local function plugin_name(spec)
  local source = spec.src:gsub("/+$", "")
  source = source:gsub("%.git$", "")
  return spec.name or vim.fs.basename(source)
end

---@param value any
---@param object_key string
---@return table[]
local function normalize_triggers(value, object_key)
  if value == nil then
    return {}
  end

  if type(value) == "string" then
    return { { [object_key] = value } }
  end

  if value[object_key] then
    return { value }
  end

  local triggers = {}
  for _, item in ipairs(value) do
    if type(item) == "string" then
      table.insert(triggers, { [object_key] = item })
    else
      table.insert(triggers, item)
    end
  end

  return triggers
end

---@param spec NnvimPackSpec
---@param load fun()
local function lazy_commands(spec, load)
  for _, command in ipairs(normalize_triggers(spec.cmd, "name")) do
    local opts = vim.tbl_extend("force", { nargs = "*", bang = true, range = true }, command.opts or {})
    vim.api.nvim_create_user_command(command.name, function(args)
      vim.api.nvim_del_user_command(command.name)
      load()

      local invocation = {
        cmd = command.name,
        args = args.fargs,
        bang = args.bang,
        mods = args.smods,
      }
      if args.range > 0 then
        invocation.range = { args.line1, args.line2 }
      end
      vim.api.nvim_cmd(invocation, {})
    end, opts)
  end
end

---@param spec NnvimPackSpec
---@param load fun()
local function lazy_events(spec, load)
  if not spec.event then
    return
  end

  local group = vim.api.nvim_create_augroup("NnvimLazy_" .. plugin_name(spec):gsub("[^%w_]", "_"), { clear = true })

  for _, trigger in ipairs(normalize_triggers(spec.event, "event")) do
    vim.api.nvim_create_autocmd(trigger.event, {
      group = group,
      pattern = trigger.pattern,
      once = true,
      callback = load,
    })
  end
end

---@param spec NnvimPackSpec
---@param load fun()
local function lazy_keys(spec, load)
  for _, key in ipairs(spec.keys or {}) do
    local lhs = key[1]
    local rhs = key[2]
    local modes = type(key.mode) == "table" and key.mode or { key.mode or "n" }
    local opts = vim.deepcopy(key)
    opts[1] = nil
    opts[2] = nil
    opts.mode = nil

    for _, mode in ipairs(modes) do
      vim.keymap.set(mode, lhs, function()
        vim.keymap.del(mode, lhs, { buffer = opts.buffer })
        load()

        if rhs then
          vim.keymap.set(mode, lhs, rhs, opts)
        end

        vim.api.nvim_feedkeys(vim.keycode(lhs), "m", false)
      end, opts)
    end
  end
end

---@param specs NnvimPackSpec|string|(NnvimPackSpec|string)[]
function M.setup(specs)
  local normalized = M.flatten(specs)
  if vim.tbl_isempty(normalized) then
    return
  end

  for index, spec in ipairs(normalized) do
    if type(spec) == "string" then
      normalized[index] = { src = spec }
    end
  end

  for _, spec in ipairs(normalized) do
    if spec.init then
      spec.init(spec)
    end
  end

  local native_specs = vim.tbl_map(function(spec)
    return {
      src = spec.src,
      name = spec.name,
      version = spec.version,
      data = spec.data,
    }
  end, normalized)
  vim.pack.add(native_specs, { load = false })

  for _, spec in ipairs(normalized) do
    local loaded = false
    local function load()
      if loaded then
        return
      end

      vim.cmd.packadd(plugin_name(spec))
      if spec.config then
        spec.config(spec)
      end
      loaded = true
    end

    lazy_commands(spec, load)
    lazy_events(spec, load)
    lazy_keys(spec, load)
    autocmd.from_spec(spec, load)

    if not spec.cmd and not spec.event and not spec.keys and not spec.autocmds then
      load()
    end
  end
end

return M
