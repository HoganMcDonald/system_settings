local autocmd = require("lib.autocmd")
local types = require("lib.types")

local M = {}

---@alias NvimGitHubSource NvimBrand<string, "github">
---@alias NvimCodebergSource NvimBrand<string, "codeberg">
---@alias NvimUrlSource NvimBrand<string, "url">
---@alias NvimPackSource NvimGitHubSource|NvimCodebergSource|NvimUrlSource

local github, unwrap_github = types.create_brand("github", types.is_string)
local codeberg, unwrap_codeberg = types.create_brand("codeberg", types.is_string)
local url, unwrap_url = types.create_brand("url", types.is_string)

local source_unwrappers = {
  github = unwrap_github,
  codeberg = unwrap_codeberg,
  url = unwrap_url,
}

---@param path string
---@return NvimGitHubSource
---@example pack.github("owner/plugin")
function M.github(path)
  assert(type(path) == "string" and path ~= "", "github path must be a non-empty string")
  return github("https://github.com/" .. path)
end

---@param path string
---@return NvimCodebergSource
---@example pack.codeberg("owner/plugin")
function M.codeberg(path)
  assert(type(path) == "string" and path ~= "", "codeberg path must be a non-empty string")
  return codeberg("https://codeberg.org/" .. path)
end

---@param source string
---@return NvimUrlSource
---@example pack.url("https://git.example.com/owner/plugin.git")
function M.url(source)
  assert(type(source) == "string" and source ~= "", "url must be a non-empty string")
  return url(source)
end

---@param value any
---@return boolean
local function is_source(value)
  return type(value) == "table" and source_unwrappers[value._brand] ~= nil
end

---@param source NvimPackSource
---@return string
local function unwrap_source(source)
  local unwrap = source_unwrappers[source._brand]
  assert(unwrap, "invalid plugin source brand")
  return unwrap(source)
end

---@class NvimPackCommand
---@field name string
---@field opts? vim.api.keyset.user_command

---@class NvimPackEvent
---@field event string|string[]
---@field pattern? string|string[]

---@class NvimPackKeymap: vim.keymap.set.Opts
---@field [1] string Left-hand side of the mapping
---@field [2]? string|function Right-hand side to install after loading
---@field mode? string|string[]

---@class NvimPackSpec
---@field src NvimPackSource
---@field name? string
---@field version? string|vim.VersionRange
---@field data? any
---@field dependencies? NvimPackSpec|NvimPackSource|(NvimPackSpec|NvimPackSource)[]
---@field init? fun(spec: NvimPackSpec)
---@field config? fun(spec: NvimPackSpec)
---@field cmd? string|NvimPackCommand|(string|NvimPackCommand)[]
---@field event? string|NvimPackEvent|(string|NvimPackEvent)[]
---@field keys? NvimPackKeymap[]
---@field autocmds? NvimAutocmdSpec[]

local function is_spec(value)
  return is_source(value) or (type(value) == "table" and is_source(value.src))
end

---@param ... NvimPackSpec|NvimPackSource|(NvimPackSpec|NvimPackSource)[]
---@return (NvimPackSpec|NvimPackSource)[]
function M.flatten(...)
  local flattened = {}

  local function visit(value)
    if value == nil then
      return
    end

    if is_spec(value) then
      if not is_source(value) and value.dependencies then
        visit(value.dependencies)
      end
      table.insert(flattened, value)
      return
    end

    if type(value) ~= "table" or value.src ~= nil then
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
---@return (NvimPackSpec|NvimPackSource)[]
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

  return specs
end

---@param spec NvimPackSpec
---@return string
local function plugin_name(spec)
  local source = unwrap_source(spec.src):gsub("/+$", "")
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

---@param spec NvimPackSpec
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

---@param spec NvimPackSpec
---@param load fun()
local function lazy_events(spec, load)
  if not spec.event then
    return
  end

  local group = vim.api.nvim_create_augroup("NvimLazy_" .. plugin_name(spec):gsub("[^%w_]", "_"), { clear = true })

  for _, trigger in ipairs(normalize_triggers(spec.event, "event")) do
    vim.api.nvim_create_autocmd(trigger.event, {
      group = group,
      pattern = trigger.pattern,
      once = true,
      callback = load,
    })
  end
end

---@param spec NvimPackSpec
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

---@type table<string, true>
local loaded_plugins = {}

---Names of the plugins that have been loaded so far.
---@return string[]
function M.loaded()
  return vim.tbl_keys(loaded_plugins)
end

---@param spec NvimPackSpec
---@return boolean
local function is_lazy(spec)
  return (spec.cmd or spec.event or spec.keys or spec.autocmds) ~= nil
end

---`vim.pack.add` behaves like `:packadd!`: every plugin directory joins
---'runtimepath', and Nvim's own startup pass then sources each `plugin/` script
---it finds there. Taking lazy plugins back off the path keeps them dormant
---until `load()` calls `:packadd`, which restores the entry and sources it then.
---@param specs NvimPackSpec[]
local function defer_lazy_plugins(specs)
  local paths = {}
  -- `info` defaults to true, which collects git branches and tags for every
  -- plugin. Only the paths are needed here.
  for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
    paths[plugin.spec.name] = plugin.path
  end

  local deferred = {}
  for _, spec in ipairs(specs) do
    local path = is_lazy(spec) and paths[plugin_name(spec)] or nil
    if path then
      deferred[path] = true
      deferred[vim.fs.joinpath(path, "after")] = true
    end
  end

  if not next(deferred) then
    return
  end

  vim.opt.runtimepath = vim.tbl_filter(function(path)
    return not deferred[path]
  end, vim.opt.runtimepath:get())
end

---@param specs NvimPackSpec|NvimPackSource|(NvimPackSpec|NvimPackSource)[]
function M.setup(specs)
  local normalized = M.flatten(specs)
  if vim.tbl_isempty(normalized) then
    return
  end

  for index, spec in ipairs(normalized) do
    if is_source(spec) then
      normalized[index] = { src = spec }
    end
  end

  local unique = {}
  local by_name = {}
  for _, spec in ipairs(normalized) do
    local name = plugin_name(spec)
    local existing = by_name[name]

    if existing then
      for key, value in pairs(spec) do
        existing[key] = value
      end
    else
      local merged = vim.tbl_extend("force", {}, spec)
      by_name[name] = merged
      table.insert(unique, merged)
    end
  end
  normalized = unique

  for _, spec in ipairs(normalized) do
    if spec.init then
      spec.init(spec)
    end
  end

  local native_specs = vim.tbl_map(function(spec)
    return {
      src = unwrap_source(spec.src),
      name = spec.name,
      version = spec.version,
      data = spec.data,
    }
  end, normalized)
  vim.pack.add(native_specs, { load = false, confirm = false })
  defer_lazy_plugins(normalized)

  for _, spec in ipairs(normalized) do
    local loaded = false
    local function load()
      if loaded then
        return
      end

      local name = plugin_name(spec)
      vim.cmd.packadd(name)
      if spec.config then
        spec.config(spec)
      end
      loaded_plugins[name] = true
      loaded = true
    end

    lazy_commands(spec, load)
    lazy_events(spec, load)
    lazy_keys(spec, load)
    autocmd.from_spec(spec, plugin_name(spec), load)

    if not spec.cmd and not spec.event and not spec.keys and not spec.autocmds then
      load()
    end
  end
end

return M
