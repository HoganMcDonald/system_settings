---@class Logger
---@field level string
---@field file string

local M = {}

-- Log levels
M.LEVELS = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4
}

-- Current log level (default to INFO)
M.current_level = M.LEVELS.INFO

-- Log file path
M.log_file = "/tmp/sketchybar.log"

---Set the logging level
---@param level number
function M.set_level(level)
  M.current_level = level
end

---Set the log file path
---@param file string
function M.set_file(file)
  M.log_file = file
end

---Internal logging function
---@param level number
---@param level_name string
---@param message string
---@param context? string
local function log_message(level, level_name, message, context)
  if level < M.current_level then
    return
  end

  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local ctx = context and ("[" .. context .. "] ") or ""
  local log_line = string.format("[%s] %s: %s%s", timestamp, level_name, ctx, message)
  
  os.execute('echo "' .. log_line .. '" >> "' .. M.log_file .. '"')
end

---Log debug message
---@param message string
---@param context? string
function M.debug(message, context)
  log_message(M.LEVELS.DEBUG, "DEBUG", message, context)
end

---Log info message
---@param message string
---@param context? string
function M.info(message, context)
  log_message(M.LEVELS.INFO, "INFO", message, context)
end

---Log warning message
---@param message string
---@param context? string
function M.warn(message, context)
  log_message(M.LEVELS.WARN, "WARN", message, context)
end

---Log error message
---@param message string
---@param context? string
function M.error(message, context)
  log_message(M.LEVELS.ERROR, "ERROR", message, context)
end

return M