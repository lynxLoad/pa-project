local M = {}

M.loaded = {}

function M.mload(path)
	if M.loaded[path] then
		return M.loaded[path]
	end
	
	local code, error = sys.load_resource(path) -- "/assets/level.lua", к примеру

	if error then
		print("File loading error:", tostring(error))
		return
	end
	if not code then
		error("Loaded data is nil, the resource is not be loaded")
		return
	end

	local chunk = loadstring(code)
	
	if not chunk then
		error("Failed loadstring function")
		return
	end
	
	local ok, result = pcall(chunk)

	if not ok then
		error("Error executing mod: " .. tostring(module))
		return
	end

	M.loaded[path] = result or true

	return M.loaded[path]
end

return M