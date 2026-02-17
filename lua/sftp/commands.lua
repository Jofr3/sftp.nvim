local config = require("sftp.config")
local sftp = require("sftp.sftp")
local watcher = require("sftp.watcher")

local M = {}

--- Register all user commands
function M.setup()
  -- Upload current file
  vim.api.nvim_create_user_command("SftpUpload", function()
    sftp.upload()
  end, { desc = "Upload current file to remote server" })

  -- Download current file
  vim.api.nvim_create_user_command("SftpDownload", function()
    sftp.download()
  end, { desc = "Download current file from remote server" })

  -- Test connection
  vim.api.nvim_create_user_command("SftpTest", function()
    sftp.test_connection()
  end, { desc = "Test SFTP connection" })

  -- Show current config
  vim.api.nvim_create_user_command("SftpStatus", function()
    local cfg = config.get()
    if not cfg then
      vim.notify("SFTP: No configuration found. Create .sftp.json in project root.", vim.log.levels.WARN)
      return
    end

    local watcher_status = watcher.status()
    local lines = {
      "SFTP Configuration:",
      "  Name: " .. (cfg.name or "not set"),
      "  Host: " .. (cfg.host or "not set"),
      "  Port: " .. (cfg.port or 22),
      "  Username: " .. (cfg.username or "not set"),
      "  Remote Path: " .. (cfg.remotePath or "/"),
      "  Upload on Save: " .. tostring(cfg.uploadOnSave),
      "  Auth: " .. (cfg.password and "password" or ("key: " .. (cfg.privateKeyPath or "default"))),
      "  Project Root: " .. (config.project_root or "not found"),
      "",
      "Watcher:",
      "  Running: " .. tostring(watcher_status.running),
      "  Watched Dirs: " .. watcher_status.watched_dirs,
      "  Pending Uploads: " .. watcher_status.pending_uploads,
    }
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Show SFTP configuration status" })

  -- Reload config
  vim.api.nvim_create_user_command("SftpReload", function()
    config.clear_cache()
    local cfg = config.load(true)
    if cfg then
      vim.notify("SFTP: Configuration reloaded", vim.log.levels.INFO)
    else
      vim.notify("SFTP: No configuration found", vim.log.levels.WARN)
    end
  end, { desc = "Reload SFTP configuration" })

  -- Start file watcher
  vim.api.nvim_create_user_command("SftpWatch", function()
    watcher.start()
  end, { desc = "Start SFTP file watcher" })

  -- Stop file watcher
  vim.api.nvim_create_user_command("SftpWatchStop", function()
    watcher.stop()
  end, { desc = "Stop SFTP file watcher" })

  -- Debug: show the command that would be run
  vim.api.nvim_create_user_command("SftpDebug", function()
    local cmd = sftp.get_debug_cmd()
    if cmd then
      vim.notify("SFTP command: " .. cmd, vim.log.levels.INFO)
    else
      vim.notify("SFTP: No configuration found", vim.log.levels.WARN)
    end
  end, { desc = "Show SFTP debug info" })

  -- Toggle watcher debug mode
  vim.api.nvim_create_user_command("SftpWatchDebug", function()
    watcher.debug = not watcher.debug
    vim.notify("SFTP: Watcher debug " .. (watcher.debug and "enabled" or "disabled"), vim.log.levels.INFO)
  end, { desc = "Toggle SFTP watcher debug mode" })

end

return M
