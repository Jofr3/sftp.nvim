local M = {}

function M.get_file_contents(project_path)
  local config_path = project_path .. "/sftp.json"
	local file = io.open(config_path, "r")
	if file then
		local output = file:read("*a")
		file:close()
		if output == "null" or output == "" or output == nil then
			return nil
		else
		 	return vim.json.decode(output)
		end
	end
	return nil
end

return M
