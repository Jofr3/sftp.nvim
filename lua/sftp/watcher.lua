local config = require("sftp.config")

local M = {}

-- Watcher state
M.handles = {}        -- fs_event handles by path
M.debounce_timers = {} -- debounce timers by filepath
M.is_running = false
M.debounce_ms = 300   -- wait 300ms before uploading
M.debug = false       -- set to true for verbose logging

--- Check if notifications should be shown
local function should_notify()
  local main = package.loaded["sftp"]
  return not (main and main.config and main.config.silent)
end

--- Debounced upload - waits for file writes to settle
---@param filepath string
local function debounced_upload(filepath)
  -- Cancel existing timer for this file
  if M.debounce_timers[filepath] then
    M.debounce_timers[filepath]:stop()
    M.debounce_timers[filepath]:close()
    M.debounce_timers[filepath] = nil
  end

  -- Create new timer
  local timer = vim.uv.new_timer()
  M.debounce_timers[filepath] = timer

  timer:start(M.debounce_ms, 0, function()
    vim.schedule(function()
      -- Clean up timer
      if M.debounce_timers[filepath] then
        M.debounce_timers[filepath]:stop()
        M.debounce_timers[filepath]:close()
        M.debounce_timers[filepath] = nil
      end

      -- Check if file should be ignored
      if config.should_ignore(filepath) then
        return
      end

      -- Check if file exists and is a regular file
      local stat = vim.uv.fs_stat(filepath)
      if not stat or stat.type ~= "file" then
        return
      end

      -- Upload the file
      require("sftp.sftp").upload(filepath)
    end)
  end)
end

--- Start watching a directory recursively (forward declaration for event handler)
---@param dir string
local watch_directory

--- Handle file system event
---@param err string|nil
---@param filename string
---@param events table
---@param watched_dir string
local function on_fs_event(err, filename, events, watched_dir)
  if err then
    vim.schedule(function()
      vim.notify("SFTP Watcher error: " .. err, vim.log.levels.ERROR)
    end)
    return
  end

  if not filename then
    return
  end

  local is_change = events and events.change or false
  local is_rename = events and events.rename or false
  if not is_change and not is_rename then
    return
  end

  local filepath = watched_dir .. "/" .. filename

  -- fs_event callbacks run in a fast-event context: defer any API/config work.
  vim.schedule(function()
    -- Debug logging
    if M.debug then
      local event_str = (is_change and "change " or "") .. (is_rename and "rename" or "")
      vim.notify("SFTP Watcher: " .. filepath .. " [" .. event_str .. "]", vim.log.levels.DEBUG)
    end

    -- On directory creation/rename, start watching it so nested files also sync.
    local stat = vim.uv.fs_stat(filepath)
    if stat and stat.type == "directory" then
      if not M.handles[filepath] and not config.should_ignore(filepath) then
        watch_directory(filepath)
      end
      return
    end

    -- Do not stat-gate files here: atomic saves can briefly hide the final path.
    -- `debounced_upload` re-checks file existence after writes settle.
    if config.should_ignore(filepath) then
      return
    end

    debounced_upload(filepath)
  end)
end

--- Recursively watch a directory
---@param dir string
watch_directory = function(dir)
  if M.handles[dir] then
    return
  end

  -- Skip ignored directories
  if config.should_ignore(dir) then
    return
  end

  -- Create watcher for this directory
  local handle = vim.uv.new_fs_event()
  if not handle then
    return
  end

  local ok, err = handle:start(dir, {}, function(err, filename, events)
    on_fs_event(err, filename, events, dir)
  end)

  if not ok then
    handle:close()
    vim.schedule(function()
      vim.notify("SFTP: Failed to watch " .. dir .. ": " .. (err or "unknown"), vim.log.levels.WARN)
    end)
    return
  end

  M.handles[dir] = handle

  -- Recursively watch subdirectories
  local scanner = vim.uv.fs_scandir(dir)
  if scanner then
    while true do
      local name, type = vim.uv.fs_scandir_next(scanner)
      if not name then
        break
      end
      if type == "directory" then
        local subdir = dir .. "/" .. name
        watch_directory(subdir)
      end
    end
  end
end

--- Start watching the project directory
---@param callback function|nil Called with (success, message)
function M.start(callback)
  if M.is_running then
    if callback then
      callback(false, "Watcher is already running")
    end
    return
  end

  local cfg = config.get()
  if not cfg then
    if callback then
      callback(false, "No SFTP configuration found")
    end
    return
  end

  local root = config.project_root
  if not root then
    if callback then
      callback(false, "No project root found")
    end
    return
  end

  -- Start watching
  watch_directory(root)

  local watch_count = vim.tbl_count(M.handles)
  if watch_count == 0 then
    if callback then
      callback(false, "Failed to start watcher: no directories could be watched")
    end
    return
  end

  M.is_running = true

  if should_notify() then
    vim.notify("SFTP: Watcher started (" .. watch_count .. " directories)", vim.log.levels.INFO)
  end

  if callback then
    callback(true, "Watcher started")
  end
end

--- Stop watching
function M.stop()
  if not M.is_running then
    return
  end

  -- Stop all fs_event handles
  for path, handle in pairs(M.handles) do
    if handle and not handle:is_closing() then
      handle:stop()
      handle:close()
    end
    M.handles[path] = nil
  end

  -- Cancel all debounce timers
  for filepath, timer in pairs(M.debounce_timers) do
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    M.debounce_timers[filepath] = nil
  end

  M.is_running = false

  if should_notify() then
    vim.notify("SFTP: Watcher stopped", vim.log.levels.INFO)
  end
end

--- Get watcher status
---@return table
function M.status()
  return {
    running = M.is_running,
    watched_dirs = vim.tbl_count(M.handles),
    pending_uploads = vim.tbl_count(M.debounce_timers),
  }
end

--- Start watcher if connection is valid
---@param callback function|nil
function M.start_if_connected(callback)
  local cfg = config.get()
  if not cfg then
    if callback then
      callback(false, "No configuration")
    end
    return
  end

  -- Test connection first, then start watcher
  require("sftp.sftp").test_connection(function(success)
    if success then
      M.start(callback)
    else
      if callback then
        callback(false, "Connection failed")
      end
    end
  end)
end

return M
