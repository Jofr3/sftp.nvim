local M = {}

M.config = {
  -- Enable upload on save globally (can be overridden per-project in .sftp.json)
  upload_on_save = true,
  -- Suppress notifications (only show errors)
  silent = false,
  -- Auto-start file watcher if SFTP project detected and connection valid
  auto_watch = true,
}

local augroup = nil

--- Setup auto-upload on save and external change detection
local function setup_auto_upload()
  if augroup then
    vim.api.nvim_del_augroup_by_id(augroup)
  end

  augroup = vim.api.nvim_create_augroup("SftpAutoUpload", { clear = true })

  -- Upload on save
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    pattern = "*",
    callback = function()
      local project_config = require("sftp.config").get()

      if project_config and project_config.uploadOnSave then
        require("sftp.sftp").upload()
      end
    end,
    desc = "SFTP: Auto-upload on save",
  })

  -- Check for external changes when focusing Neovim
  vim.api.nvim_create_autocmd("FocusGained", {
    group = augroup,
    pattern = "*",
    callback = function()
      vim.cmd("checktime")
    end,
    desc = "SFTP: Check for external changes",
  })

  -- Upload after external changes are loaded
  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = augroup,
    pattern = "*",
    callback = function()
      local project_config = require("sftp.config").get()

      if project_config and project_config.uploadOnSave then
        require("sftp.sftp").upload()
      end
    end,
    desc = "SFTP: Upload after external change",
  })

  -- Stop watcher when exiting Neovim
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      local watcher = require("sftp.watcher")
      if watcher.is_running then
        watcher.stop()
      end
    end,
    desc = "SFTP: Stop watcher on exit",
  })
end

--- Start file watcher if auto_watch enabled and connection is valid
local function try_auto_watch()
  local watcher = require("sftp.watcher")
  if watcher.is_running then
    return
  end

  local project_config = require("sftp.config").get()
  if not project_config then
    return
  end

  -- Defer to allow Neovim to fully initialize
  vim.defer_fn(function()
    require("sftp.watcher").start_if_connected()
  end, 100)
end

--- Keep trying auto-watch when opening files later in startup/session.
local function setup_auto_watch_retry()
  if not augroup then
    augroup = vim.api.nvim_create_augroup("SftpAutoUpload", { clear = true })
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    group = augroup,
    pattern = "*",
    callback = function()
      if M.config.auto_watch then
        try_auto_watch()
      end
    end,
    desc = "SFTP: Retry watcher auto-start",
  })
end

--- Setup the plugin
---@param opts table|nil
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Register commands
  require("sftp.commands").setup()

  -- Setup auto-upload if enabled
  if M.config.upload_on_save then
    setup_auto_upload()
  end

  -- Auto-start watcher if enabled
  if M.config.auto_watch then
    try_auto_watch()
    setup_auto_watch_retry()
  end
end

-- Expose submodules
M.upload = function(path, callback)
  require("sftp.sftp").upload(path, callback)
end

M.download = function(path, callback)
  require("sftp.sftp").download(path, callback)
end

M.pull = function()
  local sftp = require("sftp.sftp")
  local config = require("sftp.config")

  local target = sftp.get_remote_target_from_context()
  if not target then
    sftp.download()
    return
  end

  local local_path = config.get_local_path(target.path)
  if not local_path then
    vim.notify("SFTP: Remote path is outside configured remotePath: " .. target.path, vim.log.levels.ERROR)
    return
  end

  if target.is_directory then
    sftp.download_remote_dir(target.path, local_path)
  else
    sftp.download_remote(target.path, local_path)
  end
end

M.test_connection = function(callback)
  require("sftp.sftp").test_connection(callback)
end

M.browse = function()
  local sftp = require("sftp.sftp")
  local uris, err = sftp.get_remote_browse_uris()
  if not uris then
    vim.notify("SFTP: " .. err, vim.log.levels.ERROR)
    return
  end

  local oil_ok, oil = pcall(require, "oil")
  if oil_ok and oil and type(oil.open) == "function" then
    local ok, open_err = pcall(oil.open, uris.oil)
    if ok then
      return
    end
    vim.notify("SFTP: Oil open failed, falling back to netrw: " .. tostring(open_err), vim.log.levels.WARN)
  end

  vim.cmd("edit " .. vim.fn.fnameescape(uris.scp))
end

M.get_config = function()
  return require("sftp.config").get()
end

M.watch_start = function(callback)
  require("sftp.watcher").start(callback)
end

M.watch_stop = function()
  require("sftp.watcher").stop()
end

M.watch_status = function()
  return require("sftp.watcher").status()
end

return M
