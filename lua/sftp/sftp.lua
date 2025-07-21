local oi = require("sftp.oi")
local ui = require("sftp.ui")
local cli = require("sftp.cli")

local M = {}

local is_sftp_project = false
local sftp_project_dir = ""
local project_config = {}

function M.check_project()
	local project_path = vim.fn.getcwd()

	if project_path == "" or project_path == nil then
		is_sftp_project = false
		return
	end

	local file_contents = oi.get_file_contents(project_path)
	if file_contents then
		-- if check_project(file_contents) then
		if cli.check_connection() then
      print("connection OK")
    end

	-- check connecion
	-- if successful ceate connection
	-- end
	else
		is_sftp_project = false
	end
end

function M.check_config(config)
	local expected_options = { "port", "host", "username", "remote_path", "key" }

	for _, propName in ipairs(expected_options) do
		if config[propName] == nil then
			return false
		end
	end

	return true
end

function M.close_connection()
	is_sftp_project = false
	sftp_project_dir = ""
end

return M
