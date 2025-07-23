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

			cli.check_connection(function(success, details)
        print(vim.inspect(details))
        if not success then
          print("Error connecting to server.")
        else
          print("ok")
        end

        -- error code 23 = file not found

        -- check if actuall output of command means connection with sftp server is made
			end)
		end
	end
end

return M
