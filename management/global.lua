local M = {}

function M.screen_to_world(x, y, z, proj, view)
	local DISPLAY_WIDTH = sys.get_config_int("display.width")
	local DISPLAY_HEIGHT = sys.get_config_int("display.height")
	--local proj = camera.get_projection(camera_id)
	--local view = camera.get_view(camera_id)
	local w, h = window.get_size()

	w = w / (w / DISPLAY_WIDTH)
	h = h / (h / DISPLAY_HEIGHT)

	local inv = vmath.inv(proj * view)
	x = (2 * x / w) - 1
	y = (2 * y / h) - 1
	z = (2 * z) - 1
	local x1 = x * inv.m00 + y * inv.m01 + z * inv.m02 + inv.m03
	local y1 = x * inv.m10 + y * inv.m11 + z * inv.m12 + inv.m13
	local z1 = x * inv.m20 + y * inv.m21 + z * inv.m22 + inv.m23
	return vmath.vector3(x1, y1, z1)
	--return {x1, y1, z1}
end

return M