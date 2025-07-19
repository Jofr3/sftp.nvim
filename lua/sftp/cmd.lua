local mark = require("sftp.sftp")

local M = {}

local group = vim.api.nvim_create_augroup("sftp", { clear = true })

local function auto_cmds()
	-- vim.api.nvim_create_autocmd("BufEnter", {
	-- 	group = group,
	-- 	pattern = "*",
	-- 	callback = function()
	-- 		mark.buf_enter()
	-- 	end,
	-- })
end

local function mappings_cmds(mark_chars)
	-- vim.api.nvim_set_keymap(
	-- 	"n",
	-- 	"M",
	-- 	"<cmd>:lua require('needle.mark').add_mark()<cr>",
	-- 	{ noremap = true, silent = true }
	-- )
end

function M.setup()
	auto_cmds()
	mappings_cmds()
end

return M
