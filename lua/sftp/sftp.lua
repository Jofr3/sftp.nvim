local oi = require("sftp.oi")
local ui = require("sftp.ui")

local M = {}

local is_sftp_project = false
local sftp_project_dir = ""

function M.check_project()
  local project_path = vim.fn.getcwd()

	if project_path == "" or project_path == nil then
    is_sftp_project = false
		return
	end


  local file_contents = oi.get_file_contents(project_path)
  if file_contents then
    is_sftp_project = true
    print(vim.inspect(file_contents))

    -- check if config is valid
    check_project()
  else
    is_sftp_project = false
    print("not a sftp project")
  end
end

function M.check_config()
end

return M
