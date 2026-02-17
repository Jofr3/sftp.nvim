local M = {}

-- Default configuration (VSCode SFTP extension format)
M.defaults = {
  name = nil,
  protocol = "sftp",
  host = nil,
  port = 22,
  username = nil,
  password = nil,
  privateKeyPath = nil,
  remotePath = "/",
  uploadOnSave = true,
  ignore = { ".vscode", ".git", ".DS_Store" },
  -- Set to false to auto-accept new host keys (less secure, convenient for dev)
  strictHostKeyChecking = true,
}

-- Cached project config
M.project_config = nil
M.project_root = nil

--- Find project root by looking for .vscode/sftp.json
---@return string|nil
function M.find_project_root()
  local path = vim.fn.expand("%:p:h")
  local root = vim.fs.find(".vscode", {
    path = path,
    upward = true,
    type = "directory",
  })
  if root and #root > 0 then
    local sftp_config = root[1] .. "/sftp.json"
    if vim.fn.filereadable(sftp_config) == 1 then
      return vim.fn.fnamemodify(root[1], ":h")
    end
  end
  return nil
end

--- Load project configuration from .sftp.json
---@param force boolean|nil Force reload
---@return table|nil
function M.load(force)
  local root = M.find_project_root()
  if not root then
    return nil
  end

  -- Return cached if same project and not forcing reload
  if not force and M.project_config and M.project_root == root then
    return M.project_config
  end

  local config_path = root .. "/.vscode/sftp.json"
  local file = io.open(config_path, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  local ok, config = pcall(vim.json.decode, content)
  if not ok then
    vim.notify("SFTP: Invalid .sftp.json: " .. config, vim.log.levels.ERROR)
    return nil
  end

  -- Merge with defaults
  M.project_config = vim.tbl_deep_extend("force", M.defaults, config)
  M.project_root = root

  return M.project_config
end

--- Get current project config
---@return table|nil
function M.get()
  return M.load()
end

--- Get the remote path for a local file
---@param local_path string
---@return string|nil
function M.get_remote_path(local_path)
  local config = M.get()
  if not config or not M.project_root then
    return nil
  end

  local relative = local_path:sub(#M.project_root + 2) -- +2 for trailing slash
  local remote_base = config.remotePath

  -- Ensure remote path starts with /
  if remote_base:sub(1, 1) ~= "/" then
    remote_base = "/" .. remote_base
  end

  -- Remove trailing slash if present
  if remote_base:sub(-1) == "/" then
    remote_base = remote_base:sub(1, -2)
  end

  return remote_base .. "/" .. relative
end

--- Check if a file should be ignored
---@param filepath string
---@return boolean
function M.should_ignore(filepath)
  local config = M.get()
  if not config then
    return false
  end

  for _, pattern in ipairs(config.ignore or {}) do
    if filepath:match(pattern) then
      return true
    end
  end
  return false
end

--- Clear cached config
function M.clear_cache()
  M.project_config = nil
  M.project_root = nil
end

return M
