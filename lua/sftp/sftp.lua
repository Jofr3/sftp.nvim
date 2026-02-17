local config = require("sftp.config")

local M = {}

--- Check if notifications should be shown
local function should_notify()
  local main = package.loaded["sftp"]
  return not (main and main.config and main.config.silent)
end

--- Check if a command is executable
---@param cmd string
---@return boolean
local function is_executable(cmd)
  return vim.fn.executable(cmd) == 1
end

--- Build the sftp connection string
---@param cfg table
---@param batch_file string|nil Path to batch file (required for password auth)
---@return string[]|nil, string|nil
local function build_sftp_cmd(cfg, batch_file)
  local cmd = {}

  -- Use sshpass for password auth if password is set
  if cfg.password then
    if not is_executable("sshpass") then
      return nil, "Password auth requires 'sshpass' but it's not installed. Install it or use key-based auth."
    end
    table.insert(cmd, "sshpass")
    table.insert(cmd, "-p")
    table.insert(cmd, cfg.password)
  end

  if not is_executable("sftp") then
    return nil, "'sftp' command not found"
  end

  table.insert(cmd, "sftp")
  table.insert(cmd, "-P")
  table.insert(cmd, tostring(cfg.port))

  -- Auto-accept new host keys if strictHostKeyChecking is false
  if cfg.strictHostKeyChecking == false then
    table.insert(cmd, "-o")
    table.insert(cmd, "StrictHostKeyChecking=accept-new")
  end

  -- Add private key if specified
  if cfg.privateKeyPath and not cfg.password then
    table.insert(cmd, "-i")
    table.insert(cmd, vim.fn.expand(cfg.privateKeyPath))
  end

  -- Batch mode: use file for password auth (stdin conflicts with sshpass), stdin otherwise
  table.insert(cmd, "-b")
  if cfg.password and batch_file then
    table.insert(cmd, batch_file)
  else
    table.insert(cmd, "-")
  end

  -- User@host
  local target = cfg.username and (cfg.username .. "@" .. cfg.host) or cfg.host
  table.insert(cmd, target)

  return cmd
end

--- Run an sftp command asynchronously
---@param sftp_commands string[] SFTP batch commands
---@param on_success function|nil
---@param on_error function|nil
local function run_sftp(sftp_commands, on_success, on_error)
  local cfg = config.get()
  if not cfg then
    vim.notify("SFTP: No configuration found. Create .sftp.json in project root.", vim.log.levels.ERROR)
    return
  end

  if not cfg.host then
    vim.notify("SFTP: No host configured in .sftp.json", vim.log.levels.ERROR)
    return
  end

  local batch_input = table.concat(sftp_commands, "\n") .. "\n"
  local batch_file = nil

  -- When using password auth, write commands to temp file (stdin conflicts with sshpass)
  if cfg.password then
    batch_file = os.tmpname()
    local f = io.open(batch_file, "w")
    if f then
      f:write(batch_input)
      f:close()
    else
      vim.notify("SFTP: Failed to create temp batch file", vim.log.levels.ERROR)
      return
    end
  end

  local cmd, err = build_sftp_cmd(cfg, batch_file)
  if not cmd then
    if batch_file then os.remove(batch_file) end
    vim.notify("SFTP: " .. err, vim.log.levels.ERROR)
    if on_error then
      on_error(err, -1)
    end
    return
  end

  local stdout = {}
  local stderr = {}

  local job_id = vim.fn.jobstart(cmd, {
    stdin = cfg.password and "null" or "pipe",
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr, data)
      end
    end,
    on_exit = function(_, exit_code)
      -- Clean up temp file
      if batch_file then
        os.remove(batch_file)
      end

      if exit_code == 0 then
        if on_success then
          on_success(stdout)
        end
      else
        local err_msg = table.concat(stderr, "\n")
        if on_error then
          on_error(err_msg, exit_code)
        else
          vim.schedule(function()
            vim.notify("SFTP error: " .. err_msg, vim.log.levels.ERROR)
          end)
        end
      end
    end,
  })

  if job_id > 0 then
    if not cfg.password then
      -- Only use stdin for non-password auth
      vim.fn.chansend(job_id, batch_input)
      vim.fn.chanclose(job_id, "stdin")
    end
  else
    if batch_file then os.remove(batch_file) end
    vim.notify("SFTP: Failed to start sftp process", vim.log.levels.ERROR)
  end
end

--- Build recursive remote mkdir commands for a full directory path.
--- SFTP `mkdir` is not recursive, so we create each segment in order.
---@param remote_dir string
---@return string[]
local function build_mkdir_commands(remote_dir)
  local commands = {}
  if not remote_dir or remote_dir == "" or remote_dir == "/" then
    return commands
  end

  local is_absolute = remote_dir:sub(1, 1) == "/"
  local current = is_absolute and "" or nil

  for segment in remote_dir:gmatch("[^/]+") do
    if current == nil then
      current = segment
    elseif current == "" then
      current = "/" .. segment
    else
      current = current .. "/" .. segment
    end
    table.insert(commands, "-mkdir " .. current)
  end

  return commands
end

--- Upload a file to remote server
---@param local_path string|nil Path to upload, defaults to current buffer
---@param callback function|nil Optional callback on completion
function M.upload(local_path, callback)
  local_path = local_path or vim.fn.expand("%:p")

  if config.should_ignore(local_path) then
    vim.notify("SFTP: File is in ignore list, skipping", vim.log.levels.WARN)
    return
  end

  local remote_path = config.get_remote_path(local_path)
  if not remote_path then
    vim.notify("SFTP: Could not determine remote path", vim.log.levels.ERROR)
    return
  end

  -- Ensure remote directory exists
  local remote_dir = vim.fn.fnamemodify(remote_path, ":h")

  local commands = build_mkdir_commands(remote_dir)
  table.insert(commands, "put " .. local_path .. " " .. remote_path)

  local filename = vim.fn.fnamemodify(local_path, ":t")

  run_sftp(commands, function()
    vim.schedule(function()
      if should_notify() then
        vim.notify("SFTP: Uploaded " .. filename, vim.log.levels.INFO)
      end
      if callback then
        callback(true)
      end
    end)
  end, function(err)
    vim.schedule(function()
      -- Always show errors
      vim.notify("SFTP: Upload failed - " .. err, vim.log.levels.ERROR)
      if callback then
        callback(false, err)
      end
    end)
  end)
end

--- Download a file from remote server
---@param local_path string|nil Path to download to, defaults to current buffer
---@param callback function|nil Optional callback on completion
function M.download(local_path, callback)
  local_path = local_path or vim.fn.expand("%:p")

  local remote_path = config.get_remote_path(local_path)
  if not remote_path then
    vim.notify("SFTP: Could not determine remote path", vim.log.levels.ERROR)
    return
  end

  local commands = {
    "get " .. remote_path .. " " .. local_path,
  }

  local filename = vim.fn.fnamemodify(local_path, ":t")

  run_sftp(commands, function()
    vim.schedule(function()
      -- Reload buffer if it's the current file
      if local_path == vim.fn.expand("%:p") then
        vim.cmd("checktime")
      end
      if should_notify() then
        vim.notify("SFTP: Downloaded " .. filename, vim.log.levels.INFO)
      end
      if callback then
        callback(true)
      end
    end)
  end, function(err)
    vim.schedule(function()
      -- Always show errors
      vim.notify("SFTP: Download failed - " .. err, vim.log.levels.ERROR)
      if callback then
        callback(false, err)
      end
    end)
  end)
end

--- Get the command that would be run (for debugging)
---@return string|nil
function M.get_debug_cmd()
  local cfg = config.get()
  if not cfg then
    return nil
  end
  local batch_file = cfg.password and "/tmp/sftp_batch_XXXXX" or "-"
  local cmd, err = build_sftp_cmd(cfg, cfg.password and batch_file or nil)
  if not cmd then
    return err
  end
  return table.concat(cmd, " ")
end

--- Test connection to remote server
---@param callback function|nil
function M.test_connection(callback)
  local cfg = config.get()
  if not cfg then
    vim.notify("SFTP: No configuration found", vim.log.levels.ERROR)
    return
  end

  vim.notify("SFTP: Testing connection to " .. cfg.host .. "...", vim.log.levels.INFO)

  run_sftp({ "pwd" }, function()
    vim.schedule(function()
      vim.notify("SFTP: Connection successful!", vim.log.levels.INFO)
      if callback then
        callback(true)
      end
    end)
  end, function(err)
    vim.schedule(function()
      vim.notify("SFTP: Connection failed - " .. err, vim.log.levels.ERROR)
      if callback then
        callback(false, err)
      end
    end)
  end)
end

return M
