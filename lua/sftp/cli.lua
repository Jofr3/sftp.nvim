local oi = require("sftp.oi")
local ui = require("sftp.ui")

local M = {}

function M.check_connection()
  local result = false

	local stdout_data = {}
	local stderr_data = {}

	local cmd = "ls"
	local args = { "-la" }

  local process
	process = vim.loop.spawn(cmd, {
		args = args,
		stdio = { nil, 1, 2, },
	}, function(exit_code, signal)
		if exit_code == 0 then
      result = true
		else
      result = false
		end

		process:close()
	end)

	return result
end

return M
