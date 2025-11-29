
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

function Worker:on_message(message_id, message, sender)
	if message_id == hash("build_event") then
		local priority_task = { task_pos = nil, priority = -math.huge }
		local finded = false
		for i, mask_data in ipairs(self.map_data.build_map) do
			for j, xy in ipairs(mask_data.xy_array) do
				local task_y = xy.y
				local task_x = xy.x

				if not self.map_data.info_map[task_y][task_x].is_building then
					local path = self:solve_path(self.pos.x, self.pos.y, task_x, task_y)
					if path then
						local priority = 0
						local max_bitmask = 16 -- Кол-во масок для плановых тайлов
						local max_distance = 5 -- Макс. расстояние
						local points = #path
						local ndistance = points / max_distance
						local nmask = (mask_data.bitmask + 1) / max_bitmask

						priority = nmask - ndistance

						if priority > priority_task.priority then
							priority_task.priority = priority
							priority_task.task_pos = { x = task_x, y = task_y }
							finded = true
						end
					end
				end
			end
		end
		if finded then
			self.map_data.info_map[priority_task.task_pos.y][priority_task.task_pos.x].is_building = true
			self:add_task({ type = Pawn.TASK_TYPES.BUILD, task_pos = priority_task.task_pos })
			return
		else
			return
		end
	end
end

function Worker:do_task(task, dt)
	Pawn.do_task(self, task, dt)
	
	if task.task_pos.x ~= self.pos.x or task.task_pos.y ~= self.pos.y then

		if self.state ~= Pawn.STATES.MOVING then
			self:add_task({ type = Pawn.TASK_TYPES.MOVE, task_pos = task.task_pos }, 1)
		end
		return
	end
end

return Worker













