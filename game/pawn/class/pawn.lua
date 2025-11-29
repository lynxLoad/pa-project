local Pawn = {}
Pawn.__index = Pawn

-- Состояния
local STATES = {
	IDLE = "idle",
	PATROL = "patrol",
	MOVING = "moving",
	TASK = "task"
}

function Pawn.new(pos_x, pos_y, map_data)
	local self = setmetatable({}, Pawn)
	
	self.map_data = map_data
	self.task = {}
	self.health = 100
	self.move_speed = 100
	self.path = {}
	self.direction = { x = 0, y = 0 }
	self.velocity = { x = 0, y = 0 }
	self.pos = { x = pos_x, y = pos_y }
	self.target_pos = {x = 1, y = 1}
	self.world_pos = {
		x = self.map_data.tile_size * (self.pos.x - 1) + self.map_data.tile_size / 2, 
		y = self.map_data.tile_size * (self.pos.y - 1) + self.map_data.tile_size / 2
	}

	-- State machine
	self.state = STATES.IDLE
	self.state_time = 0

	return self
end

function Pawn:update(dt)
	self.state_time = self.state_time + dt

	if #self.task > 0 then
		self:set_state(STATES.TASK)
	end

	-- Обработка текущего состояния
	if self.state == STATES.IDLE then
		self:update_idle(dt)
	elseif self.state == STATES.PATROL then
		self:update_patrol(dt)
	elseif self.state == STATES.MOVING then
		self:update_moving(dt)
	elseif self.state == STATES.TASK then
		self:update_task(dt)
	end
end

function Pawn:on_message(message_id, message, sender)
	-- Прием сообщений
end

function Pawn:set_state(new_state)
	if self.state == new_state then return end

	-- Вход в новое состояние
	self.state = new_state
	self.state_time = 0

	--print("Pawn state changed to:", new_state)
end

function Pawn:update_idle(dt)
	-- После некоторого времени бездействия начинаем патрулирование
	self.direction = { x = 0, y = 0 }
	if self.state_time > 1 then
		if #self.task > 0 then
			self:set_state(STATES.TASK)
		else
			self:set_state(STATES.PATROL)
		end
	end
end

function Pawn:update_patrol(dt)
	-- Ищем доступный путь
	for i = 1, 100 do -- TODO: может быть и такое, что пешка заперта. Надо будет это учесть
		self.target_pos.x = math.random(1, self.map_data.width)
		self.target_pos.y = math.random(1, self.map_data.height)

		local path = self:solve_path(self.pos.x, self.pos.y, self.target_pos.x, self.target_pos.y)

		if path and #path > 1 then
			table.remove(path, 1)
			self.path = path
			self:set_state(STATES.MOVING)
			return
		end
	end
	self:set_state(STATES.IDLE)
end

function Pawn:update_moving(dt)
	if #self.path == 0 then
		self:set_state(STATES.IDLE)
		return
	end

	local target_tile = self.path[1]

	local function is_wall_at(x, y)
		return self.map_data.info_map[y] and 
		self.map_data.info_map[y][x].is_wall == true
	end

	-- Проверка целевого тайла
	if is_wall_at(target_tile.x, target_tile.y) then
		self:set_state(STATES.IDLE)
		return
	end
-- 
-- 	-- Проверка диагональных препятствий
-- 	local sign_dir = { x = math.sign(self.direction.x), y = math.sign(self.direction.y) }
-- 	if sign_dir.x ~= 0 and sign_dir.y ~= 0 then
-- 		-- При движении по диагонали блокируем, если есть препятствие
-- 		-- по одной из осей на пути
-- 		if is_wall_at(target_tile.x, math.floor(self.pos.y)) or 
-- 		is_wall_at(math.floor(self.pos.x), target_tile.y) then
-- 			self:set_state(STATES.IDLE)
-- 			return
-- 		end
-- 	end
	
	local target_world_pos = { x = self.map_data.tile_size * (target_tile.x - 1) + self.map_data.tile_size / 2, 
		y = self.map_data.tile_size * (target_tile.y - 1) + self.map_data.tile_size / 2
	}

	local delta_x = target_world_pos.x - self.world_pos.x
	local delta_y = target_world_pos.y - self.world_pos.y
	local distance_squared = delta_x * delta_x + delta_y * delta_y

	local arrival_threshold = 25

	if distance_squared < arrival_threshold then
		-- Достигли цели, обновляем позицию и переходим к следующей точке
		self.pos = {x = target_tile.x, y = target_tile.y}

		table.remove(self.path, 1)

		if #self.path == 0 then
			if #self.task > 0 then
				self:set_state(STATES.TASK)
			else
				self:set_state(STATES.IDLE)
			end
		end
	else
		-- Двигаемся к цели
		local distance = math.sqrt(distance_squared)
		
		local target_dir = {
			x = delta_x / distance,
			y = delta_y / distance
		}

		local TURN_SPEED = 12  -- скорость поворота (чем больше — тем резче поворот)

		-- Lerp направления
		self.direction.x = self.direction.x + (target_dir.x - self.direction.x) * TURN_SPEED * dt
		self.direction.y = self.direction.y + (target_dir.y - self.direction.y) * TURN_SPEED * dt

		-- Нормализуем
		local len = math.sqrt(self.direction.x^2 + self.direction.y^2)
		if len > 0 then
			self.direction.x = self.direction.x / len
			self.direction.y = self.direction.y / len
		end

		self.world_pos.x = self.world_pos.x + self.direction.x * self.move_speed * dt
		self.world_pos.y = self.world_pos.y + self.direction.y * self.move_speed * dt
	end
end

function Pawn:update_task(dt)
	if #self.task == 0 then
		self:set_state(STATES.IDLE)
		return
	end

	-- Логика выполнения задач
	local current_task = self.task[1]
	self:do_task(current_task, dt)
end

function Pawn:do_task(task, dt)
	-- Реализация выполнения конкретной задачи
	-- После выполнения: table.remove(self.task, 1)
end

function Pawn:add_task(task)
	table.insert(self.task, task)
end

function Pawn:take_damage(damage)
	self.health = math.max(0, self.health - damage)
end

function Pawn:solve_path(start_x, start_y, end_x, end_y)
	local status, size, total_cost, path = astar.solve(start_x, start_y, end_x, end_y, 0)

	if status == astar.SOLVED then
		return path
	elseif status == astar.NO_SOLUTION then
		return nil
	elseif status == astar.START_END_SAME then
		return nil
	end
end

return Pawn