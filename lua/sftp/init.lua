local M = {}

M.config = {
  -- Enable upload on save globally (can be overridden per-project in .sftp.json)
  upload_on_save = true,
  -- Suppress notifications (only show errors)
  silent = false,
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
end

-- Expose submodules
M.upload = function(path, callback)
  require("sftp.sftp").upload(path, callback)
end

M.download = function(path, callback)
  require("sftp.sftp").download(path, callback)
end

M.test_connection = function(callback)
  require("sftp.sftp").test_connection(callback)
end

M.get_config = function()
  return require("sftp.config").get()
end

return M
