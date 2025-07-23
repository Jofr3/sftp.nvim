local oi = require("sftp.oi")
local ui = require("sftp.ui")
local cli = require("sftp.cli")

local M = {}

local plugin_opts = {}
local connected = false

function M.setup(opts)
	plugin_opts = opts.projects or {}
end

function M.check_project()
  connected = false
	local current_path = vim.fn.getcwd()

	for key, project in pairs(plugin_opts) do
		if project.local_path == current_path and project.host ~= nil and project.remote_path ~= nil then
			print("in a sftp project")

      -- connected = cli.check_connection()
		end
	end
end

return M
