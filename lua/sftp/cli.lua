local oi = require("sftp.oi")
local ui = require("sftp.ui")

local M = {}

function M.check_connection(callback)
  -- rsync -avz ~/lsw/myclientum-new/test1.md myclientum_dev:/dev.myclientum.com/test.md
	local cmd = "rsync"
	local args = { "-avz", "~/lsw/myclientum-new/test1.md", "myclientum_dev:/dev.myclientum.com/test.md" }

	local stdout_data = {}
	local stderr_data = {}

	local stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)

	local process
	process = vim.loop.spawn(cmd, {
		args = args,
		stdio = { nil, stdout, stderr },
	}, function(exit_code, signal)
		stdout:close()
		stderr:close()
		process:close()

		local result = (exit_code == 0)
		callback(result, {
			exit_code = exit_code,
			signal = signal,
			stdout = table.concat(stdout_data),
			stderr = table.concat(stderr_data),
		})
	end)

	stdout:read_start(function(err, data)
		if err then
		elseif data then
			table.insert(stdout_data, data)
		end
	end)

	stderr:read_start(function(err, data)
		if err then
		elseif data then
			table.insert(stderr_data, data)
		end
	end)
end

return M
