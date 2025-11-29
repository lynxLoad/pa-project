
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
		local priority_task = { task, priority }
		for i, mask_data in ipairs(self.map_data.build_map) do
			for j, xy in ipairs(mask_data.xy_array) do
				local y_str, x_str = xy:match("^(%d+):(%d+)$")
				local y = tonumber(y_str)
				local x = tonumber(x_str)

				if not self.map_data.info_map[y][x].is_building then
					
				end
			end
		end
	end
end

return Worker