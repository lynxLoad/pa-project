local TILE_MAPPING = require("game.tilemap.autotiling.bitmask_map")

local DIRECTION_MASKS = {
	N  = 1, E  = 2, S  = 4, W  = 8,
	NE = 16, NW = 32, SE = 64, SW = 128
}
local EMPTY_TILE = -1

local Map = {}
Map.__index = Map

-- Создание нового экземпляра карты
function Map.new()
	local self = setmetatable({}, Map)
	self.map = {}
	return self
end

-- Инициализация карты
function Map:init(tileset, input_map, width, height)
	self.map = {
		width = width,
		height = height,
		data = {}
	}
	
	for y = 1, self.map.height do
		self.map.data[y] = {}
		for x = 1, self.map.width do
			if input_map[y][x] ~= 0 then
				self.map.data[y][x] = 1
			else
				self.map.data[y][x] = EMPTY_TILE
			end
		end
	end

	for y = 1, self.map.height do
		for x = 1, self.map.width do
			if self.map.data[y][x] ~= EMPTY_TILE then
				self.map.data[y][x] = self:set_autotile(tileset, x, y)
			end
		end
	end

	return self.map
end

-- Добавление тайла
function Map:new_tile(tileset, x, y)
	self.map.data[y][x] = 1
	return self:update_tiles(tileset, x, y)
end

-- Удаление тайла
function Map:remove_tile(tileset, x, y)
	self.map.data[y][x] = EMPTY_TILE -- TODO: удаленный тайл не считается обновленным
	return self:update_tiles(tileset, x, y)
end

function Map:update_tiles(tileset, x, y)
	local updated_tiles = {}
	local main_tile = self:update_single_tile(tileset, x, y)
	local n_updated = self:update_neighbors(tileset, x, y)

	table.insert(updated_tiles, main_tile)
	for _, ut in ipairs(n_updated) do
		table.insert(updated_tiles, ut)
	end

	return updated_tiles
end

-- Проверка выхода за границы
function Map:is_out_of_bounds(x, y)
	return x < 1 or x > self.map.width or y < 1 or y > self.map.height
end

-- Поиск маски
function Map:find_mask(x, y)
	local mask = 0
	local xm, xp, ym, yp = x - 1, x + 1, y - 1, y + 1
	local tiles = self.map.data
	local width = self.map.width
	local height = self.map.height

	local row_curr = tiles[y] or {}
	local row_prev = ym >= 1 and tiles[ym] or {}
	local row_next = yp <= height and tiles[yp] or {}

	local has_N = yp <= height and row_next[x] and row_next[x] ~= EMPTY_TILE
	local has_E = xp <= width and row_curr[xp] and row_curr[xp] ~= EMPTY_TILE
	local has_S = ym >= 1 and row_prev[x] and row_prev[x] ~= EMPTY_TILE
	local has_W = xm >= 1 and row_curr[xm] and row_curr[xm] ~= EMPTY_TILE

	if has_N then mask = mask + DIRECTION_MASKS.N end
	if has_E then mask = mask + DIRECTION_MASKS.E end
	if has_S then mask = mask + DIRECTION_MASKS.S end
	if has_W then mask = mask + DIRECTION_MASKS.W end

	if has_N and has_E and xp <= width and row_next[xp] and row_next[xp] ~= EMPTY_TILE then
		mask = mask + DIRECTION_MASKS.NE
	end
	if has_S and has_E and xp <= width and row_prev[xp] and row_prev[xp] ~= EMPTY_TILE then
		mask = mask + DIRECTION_MASKS.SE
	end
	if has_S and has_W and xm >= 1 and row_prev[xm] and row_prev[xm] ~= EMPTY_TILE then
		mask = mask + DIRECTION_MASKS.SW
	end
	if has_N and has_W and xm >= 1 and row_next[xm] and row_next[xm] ~= EMPTY_TILE then
		mask = mask + DIRECTION_MASKS.NW
	end

	return mask
end

-- Установка автотайла
function Map:set_autotile(tileset, x, y)
	local mask = self:find_mask(x, y)
	local tile_id = TILE_MAPPING[tileset][mask]
	if not tile_id then
		print("Warning: No tile data for mask " .. tostring(mask) .. " at (" .. x .. ", " .. y .. ")")
		return -1
	end
	return tile_id
end

-- Обновление одного тайла
function Map:update_single_tile(tileset, x, y)
	if self:is_out_of_bounds(x, y) then return end
	local row = self.map.data[y]
	if not row or row[x] == EMPTY_TILE then return end
	self.map.data[y][x] = self:set_autotile(tileset, x, y) or EMPTY_TILE
	return {x = x, y = y, tile_id = self.map.data[y][x]}
end

-- Получение соседей
function Map:get_neighbors(x, y)
	local neighbors = {}
	for dy = -1, 1 do
		for dx = -1, 1 do
			if not (dx == 0 and dy == 0) then
				table.insert(neighbors, {x + dx, y + dy})
			end
		end
	end
	return neighbors
end

-- Обновление соседей
function Map:update_neighbors(tileset, x, y)
	local updated = {}
	for _, coord in ipairs(self:get_neighbors(x, y)) do
		local info = self:update_single_tile(tileset, coord[1], coord[2])
		if info then table.insert(updated, info) end
	end

	return updated
end

return Map
