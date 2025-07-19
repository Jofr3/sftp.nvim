local M = {}

function M.read_data(file_path)
	local file = io.open(file_path, "r")
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

function M.write_data(data)
	local file = io.open(file_path, "w")
	if file then
		local input = vim.json.encode(data)
		file:write(input)
		file:close()
	end
end

return M
