local M = {}

-- Ваша существующая функция screen_to_world
function M.screen_to_world(x, y, z, proj, view)
	local DISPLAY_WIDTH = sys.get_config_int("display.width")
	local DISPLAY_HEIGHT = sys.get_config_int("display.height")
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
end

-- Новая функция world_to_screen
function M.world_to_screen(x, y, z, proj, view)
	local DISPLAY_WIDTH = sys.get_config_int("display.width")
	local DISPLAY_HEIGHT = sys.get_config_int("display.height")
	local w, h = window.get_size()

	-- Преобразуем мировые координаты в пространство отсечения
	local world_pos = vmath.vector4(x, y, z, 1)
	local clip_pos = proj * view * world_pos

	-- Нормализуем координаты в NDC (Normalized Device Coordinates)
	local ndc_x = clip_pos.x / clip_pos.w
	local ndc_y = clip_pos.y / clip_pos.w
	-- local ndc_z = clip_pos.z / clip_pos.w -- z может быть использован для глубины, но обычно не нужен

	-- Преобразуем NDC в экранные координаты
	local screen_x = (ndc_x + 1) * 0.5 * w
	local screen_y = (ndc_y + 1) * 0.5 * h

	return vmath.vector3(screen_x, screen_y, 0)
end