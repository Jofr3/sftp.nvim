local sftp = require("sftp.sftp")

local M = {}

local group = vim.api.nvim_create_augroup("sftp", { clear = true })

local upload_file_autocmd = nil

local function auto_cmds()
	vim.api.nvim_create_autocmd("DirChanged", {
		group = group,
		callback = function()
			sftp.check_project()
		end,
	})

	vim.api.nvim_create_autocmd("VimEnter", {
		group = group,
		callback = function()
			sftp.check_project()
		end,
	})
end

function M.setup()
	auto_cmds()
end

return M
