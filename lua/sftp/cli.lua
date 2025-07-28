local oi = require("sftp.oi")

local M = {}

function M.execute_command(command, arguments, callback)
	local stdout_data = {}
	local stderr_data = {}
	local stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)
	local process

	process = vim.loop.spawn(command, {
		args = arguments or {},
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

function M.upload_file(command, arguments, callback)
	print(command, vim.inspect(arguments))
	M.execute_command(command, arguments, callback)
end

return M
