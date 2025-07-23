local cmd = require("sftp.cmd")
local sftp = require("sftp.sftp")

local M = {}

function M.setup(opts)
  sftp.setup(opts)
	cmd.setup()
end

return M
