local Pawn = {}
Pawn.__index = Pawn

-- Состояния
Pawn.STATES = {
	IDLE = "idle",
	PATROL = "patrol",
	MOVING = "moving",
	TASK = "task"
}
Pawn.TASK_TYPES = {
	BUILD = "build",
	MOVE = "move"
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
	self.state = Pawn.STATES.IDLE
	self.state_time = 0

	return self
end

function Pawn:update(dt)
	self.state_time = self.state_time + dt

	if #self.task > 0 and self.state ~= Pawn.STATES.MOVING then
		self:set_state(Pawn.STATES.TASK)
	end

	-- Обработка текущего состояния
	if self.state == Pawn.STATES.IDLE then
		self:update_idle(dt)
	elseif self.state == Pawn.STATES.PATROL then
		self:update_patrol(dt)
	elseif self.state == Pawn.STATES.MOVING then
		self:update_moving(dt)
	elseif self.state == Pawn.STATES.TASK then
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
	print(self.state_time)
	if self.state_time > 1 then
		if #self.task > 0 then
			self:set_state(Pawn.STATES.TASK)
		else
			self:set_state(Pawn.STATES.PATROL)
		end
	end
end

function Pawn:update_patrol(dt)
	-- Определяем радиус поиска
	local search_radius = 10

	-- Ищем доступный путь в пределах радиуса
	for i = 1, 100 do
		-- Генерируем точку в квадратной области вокруг пешки
		local min_x = math.max(1, self.pos.x - search_radius)
		local max_x = math.min(self.map_data.width, self.pos.x + search_radius)
		local min_y = math.max(1, self.pos.y - search_radius)
		local max_y = math.min(self.map_data.height, self.pos.y + search_radius)

		self.target_pos.x = math.random(min_x, max_x)
		self.target_pos.y = math.random(min_y, max_y)

		-- Проверяем, что целевая точка отличается от текущей
		if self.target_pos.x ~= self.pos.x or self.target_pos.y ~= self.pos.y then
			local path = self:solve_path(self.pos.x, self.pos.y, self.target_pos.x, self.target_pos.y)

			if path and #path > 1 then
				table.remove(path, 1)
				self.path = path
				self:set_state(Pawn.STATES.MOVING)
				return
			end
		end
	end

	self:set_state(Pawn.STATES.IDLE)
end

-- Вставь это вместо твоего update_moving
function Pawn:update_moving(dt)
	-- Если пути нет — прекращаем движение
	if not self.path or #self.path == 0 then
		if self.task[1] and self.task[1].type == Pawn.TASK_TYPES.MOVE then
			table.remove(self.task, 1)
		end

		if #self.task > 0 then
			self:set_state(Pawn.STATES.TASK)
		else
			self:set_state(Pawn.STATES.IDLE)
		end
		return
	end

	----------------------------------------------------------------------
	-- Берём текущий целевой тайл из path (убедимся, что path начинается НЕ с текущего тайла)
	----------------------------------------------------------------------
	local tile_size = self.map_data.tile_size

	-- Если path[1] равен текущему тайлу — удалим его (чтобы целевой тайл был "следующим")
	local first = self.path[1]
	if first and first.x == self.pos.x and first.y == self.pos.y then
		table.remove(self.path, 1)
		-- если путь опустел после удаления — обработаем как окончание
		if not self.path or #self.path == 0 then
			if self.task[1] and self.task[1].type == Pawn.TASK_TYPES.MOVE then
				table.remove(self.task, 1)
			end
			if #self.task > 0 then
				self:set_state(Pawn.STATES.TASK)
			else
				self:set_state(Pawn.STATES.IDLE)
			end
			return
		end
	end

	local target_tile = self.path[1]
	if not target_tile then
		-- нечего делать
		self.path = {}
		self:set_state(Pawn.STATES.IDLE)
		return
	end

	-- Валидность тайла (если нужно, можно убрать, но оставлю защиту)
	if not self.map_data.info_map[target_tile.y] or not self.map_data.info_map[target_tile.y][target_tile.x] then
		self.path = {}
		self:set_state(Pawn.STATES.IDLE)
		return
	end

	if self.map_data.info_map[target_tile.y][target_tile.x].is_wall then
		-- путь сломан, прекращаем
		self.path = {}
		self:set_state(Pawn.STATES.IDLE)
		return
	end

	----------------------------------------------------------------------
	-- Рассчёт мировых координат центра целевого тайла
	----------------------------------------------------------------------
	local target_world_x = (target_tile.x - 1) * tile_size + tile_size * 0.5
	local target_world_y = (target_tile.y - 1) * tile_size + tile_size * 0.5

	----------------------------------------------------------------------
	-- Вектор до цели и защита от деления на ноль
	----------------------------------------------------------------------
	local dx = target_world_x - self.world_pos.x
	local dy = target_world_y - self.world_pos.y
	local dist_sq = dx*dx + dy*dy

	-- Если уже практически в центре — считаем достигшим
	local ARRIVE_DIST = tile_size * 0.2
	if dist_sq <= ARRIVE_DIST * ARRIVE_DIST then
		-- Устанавливаем точную tile-позицию (pos) и world_pos в центр целевого тайла
		self.pos.x = target_tile.x
		self.pos.y = target_tile.y
		-- Синхронизируем world_pos аккуратно (без "прыжков"): прямой присвоение допустим, 
		-- т.к. визуально мы уже очень близко (меньше ARRIVE_DIST)
		self.world_pos.x = target_world_x
		self.world_pos.y = target_world_y

		-- Удаляем первый элемент пути
		table.remove(self.path, 1)

		-- Завершаем или продолжаем
		if #self.path == 0 then
			if self.task[1] and self.task[1].type == Pawn.TASK_TYPES.MOVE then
				table.remove(self.task, 1)
			end
			if #self.task > 0 then
				self:set_state(Pawn.STATES.TASK)
			else
				self:set_state(Pawn.STATES.IDLE)
			end
		end

		return
	end

	-- dist (положительное)
	local dist = math.sqrt(dist_sq)
	-- безопасный target_dir
	local target_dir_x, target_dir_y = 0, 0
	if dist > 0 then
		target_dir_x = dx / dist
		target_dir_y = dy / dist
	else
		-- маловероятно, но защитимся
		target_dir_x, target_dir_y = 0, 0
	end

	----------------------------------------------------------------------
	-- Движение: не позволяем "перепрыгнуть" цель за тик
	----------------------------------------------------------------------
	local step = self.move_speed * dt

	-- Если шаг больше или равен расстоянию — добегаем до цели точно этим тиком
	if step >= dist then
		-- добегаем ровно до центра целевого тайла
		self.world_pos.x = target_world_x
		self.world_pos.y = target_world_y

		-- Обновим pos и удалим тайл как в блоке выше
		self.pos.x = target_tile.x
		self.pos.y = target_tile.y
		table.remove(self.path, 1)

		if #self.path == 0 then
			if self.task[1] and self.task[1].type == Pawn.TASK_TYPES.MOVE then
				table.remove(self.task, 1)
			end
			if #self.task > 0 then
				self:set_state(Pawn.STATES.TASK)
			else
				self:set_state(Pawn.STATES.IDLE)
			end
		end

		return
	end

	----------------------------------------------------------------------
	-- Иначе двигаемся частично: применяем направление
	-- Я делаю direction = target_dir (без агрессивного LERP), чтобы
	-- гарантировать следование по линии к центру тайла.
	-- Если хочешь плавный поворот — можно заменить на LERP с малой скоростью.
	----------------------------------------------------------------------
	self.direction.x = target_dir_x
	self.direction.y = target_dir_y

	-- Применяем движение
	self.world_pos.x = self.world_pos.x + self.direction.x * step
	self.world_pos.y = self.world_pos.y + self.direction.y * step

	-- Обновляем pos в соответствие с world_pos (полезно для логики вне движения)
	self.pos.x = math.floor(self.world_pos.x / tile_size) + 1
	self.pos.y = math.floor(self.world_pos.y / tile_size) + 1
end

function Pawn:update_task(dt)
	if #self.task == 0 then
		self:set_state(Pawn.STATES.IDLE)
		return
	end

	-- Логика выполнения задач
	local current_task = self.task[1]
	self:do_task(current_task, dt)
end

-- Рекомендованное изменение в Pawn:solve_path/в do_task
-- В do_task мы будем гарантированно удалять первый элемент пути, если он равен текущему тайлу.
function Pawn:do_task(task, dt)
	if task.type == Pawn.TASK_TYPES.MOVE then
		local path = self:solve_path(self.pos.x, self.pos.y, task.task_pos.x, task.task_pos.y)
		if path and #path > 0 then
			-- Если путь начинается с текущего тайла — удаляем
			if path[1].x == self.pos.x and path[1].y == self.pos.y then
				table.remove(path, 1)
			end
			self.path = path
			self:set_state(Pawn.STATES.MOVING)
		else
			-- нет пути — убираем задачу
			table.remove(self.task, 1)
		end
		return
	end
end

function Pawn:add_task(task, pos)
	if pos then
		table.insert(self.task, pos, task)
	else
		table.insert(self.task, task)
	end
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