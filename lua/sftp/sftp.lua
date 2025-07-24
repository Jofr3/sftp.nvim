local oi = require("sftp.oi")
local ui = require("sftp.ui")
local cli = require("sftp.cli")

local M = {}

local plugin_opts = {}
local project_opts = {}
local sftp_project = false

local upload_file_autocmd = nil

function M.setup(opts)
	plugin_opts = opts.projects or {}
end

local function upload_file()
	if not sftp_project then
		return
	end

	local file_path = vim.api.nvim_buf_get_name(0)
	if not file_path then
		return
	end

	local file_name = vim.fn.fnamemodify(file_path, ":t")
	if not file_name then
		return
	end

	local remote_file_destination = string.gsub(file_path, "^" .. project_opts.local_path .. "/?", "")
	local remote_path = project_opts.host .. ":" .. project_opts.remote_path .. "/" .. remote_file_destination

	-- print("rsync -avz " .. file_path .. " " .. remote_path)

	cli.upload_file("rsync", { "-avz", file_path, remote_path }, function(success, info)
	   print(vim.inspect(info))
		if not success then
			print("Error")
		else
			print("Success")
		end
	end)

	-- error code 23 = file not found
end

local function create_autocmd()
	if not upload_file_autocmd then
		upload_file_autocmd = vim.api.nvim_create_autocmd("BufWritePost", {
			group = group,
			callback = function()
				upload_file()
			end,
		})
	end
end

local function clear_autocmd()
	if upload_file_autocmd then
		vim.api.nvim_del_autocmd(upload_file_autocmd)
	end
end

function M.check_project()
	local current_path = vim.fn.getcwd()

	for _, project in pairs(plugin_opts) do
		if project.local_path == current_path and project.host ~= nil and project.remote_path ~= nil then
			project_opts = project
			sftp_project = true
			create_autocmd()
			return
		end
	end

	project_opts = {}
	sftp_project = false
	clear_autocmd()
end

return M
