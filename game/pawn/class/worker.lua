
local Pawn = require("game.pawn.class.pawn")

-- Создаем класс-наследник
local Worker = {}
Worker.__index = Worker

-- Наследуем от Pawn
setmetatable(Worker, {__index = Pawn})

function Worker.new(pos_x, pos_y, map_data)
	local self = Pawn.new(pos_x, pos_y, map_data)  -- вызываем конструктор родителя
	setmetatable(self, Worker)  -- устанавливаем метатаблицу наследника
	
	return self
end

function Worker:think()
	-- Если уже есть задача — не думаем
	if #self.task > 0 then
		return
	end

	-- Если нет задач строительства — ничего не делаем
	if #self.map_data.build_map == 0 then
		return
	end

	local best = nil

	-- Ищем ЛУЧШУЮ свободную задачу (ещё не reserved и не построена)
	for _, mask_data in ipairs(self.map_data.build_map) do
		for _, xy in ipairs(mask_data.xy_array) do
			local tx, ty = xy.x, xy.y
			local tile = self.map_data.info_map[ty][tx]

			-- Фильтр задач
			if not tile.is_wall and not tile.reserved_by then

				-- Пытаемся найти путь (A*)
				local path, cost = self:solve_path(self.pos.x, self.pos.y, tx, ty)
				if path then
					local max_bitmask = 16
					local max_distance = 0.1

					local nd = cost / max_distance
					local nm = (mask_data.bitmask + 1) / max_bitmask
					local priority = nm - nd

					if not best or priority > best.priority then
						best = {
							priority = priority,
							task_pos = { x = tx, y = ty },
							path = path,
							tile = tile
						}
					end
				end
			end
		end
	end

	-- Нет свободных задач → выходим
	if not best then
		return
	end

	----------------------------------------------------------------------
	-- ВАЖНО: резервируем задачу ТОЛЬКО когда павн её выбрал
	----------------------------------------------------------------------
	best.tile.reserved_by = self  -- или self.id, если есть id

	-- Добавляем задачу в очередь
	self:add_task({
		type = Pawn.TASK_TYPES.BUILD,
		task_pos = best.task_pos,
		build_time_left = .1
	})
end


function Worker:do_task(task, dt)
	-- Вызываем базовый для совместимости (MOVE обрабатывается там, но здесь перехватываем всё)
	Pawn.do_task(self, task, dt)

	if task.type == Pawn.TASK_TYPES.MOVE then
		-- Если MOVE уже обработан в Pawn (path установлен), ничего extra
		return false  -- Продолжается
	end

	if task.type == Pawn.TASK_TYPES.BUILD then
		local tx, ty = task.task_pos.x, task.task_pos.y
		local tile = self.map_data.info_map[ty][tx]

		-- Проверка валидности тайла/резерва
		if not tile or tile.reserved_by ~= self  then
			print("DEBUG:SCRIPT: BUILD failed - invalid/reserved by other at (" .. tx .. "," .. ty .. ")")
			-- Release если наш
			if tile and tile.reserved_by == self then
				tile.reserved_by = nil
			end
			table.remove(self.task, 1)
			self:think()  -- Найдём новую
			return true  -- Завершено (удалено)
		end

		-- Если не на позиции — генерируем MOVE
		if (task.task_pos.x ~= self.pos.x or task.task_pos.y ~= self.pos.y) then
			print("DEBUG:SCRIPT: BUILD - not at pos, adding MOVE to (" .. tx .. "," .. ty .. ")")
			local path = self:solve_path(self.pos.x, self.pos.y, tx, ty)
			table.remove(path, #path) -- FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
			if not path or #path == 0 then
				-- Блокировка: release и удаляем BUILD
				print("DEBUG:SCRIPT: No path to BUILD (" .. tx .. "," .. ty .. ") - releasing")
				tile.reserved_by = nil
				table.remove(self.task, 1)
				return true  -- Завершено
			end
			-- Удаляем старый MOVE если был (но в Pawn он уже не висит)
			if #self.task > 1 and self.task[1].type == Pawn.TASK_TYPES.MOVE then
				table.remove(self.task, 1)
			end
			-- Вставляем MOVE перед BUILD
			self:add_task({ type = Pawn.TASK_TYPES.MOVE, task_pos = task.task_pos }, 1)
			
			-- Pawn.do_task обработает его на следующем тике
			return false  -- Продолжается
		end

		-- На позиции: строим с таймером
		if not task.build_time_left then
			task.build_time_left = 2.0  -- Инициализация, если забыли в think()
		end
		task.build_time_left = task.build_time_left - dt
		print("DEBUG:SCRIPT: Building at (" .. tx .. "," .. ty .. ") - time left: " .. task.build_time_left)

		if task.build_time_left > 0 then
			-- Анимация/прогресс продолжается
			return false  -- Продолжается
		end

		-- Таймер истёк: завершаем стройку
		print("DEBUG:SCRIPT: BUILD completed at (" .. tx .. "," .. ty .. ")")
		tile.is_building = true
		tile.reserved_by = nil
		table.remove(self.task, 1)
		msg.post(require("game.entity.entity").tilemap.id, "building", { x = tx, y = ty })
		self:think()  -- Ищем новую задачу
		return true  -- Завершено
	end

	-- Неизвестный тип
	print("DEBUG:SCRIPT: Unknown task type: " .. tostring(task.type))
	table.remove(self.task, 1)
	return true
end

return Worker













