
local Pawn = require("game.pawn.class.pawn")

-- Создаем класс-наследник
local Worker = {}
Worker.__index = Worker

-- Наследуем от Pawn
setmetatable(Worker, {__index = Pawn})

function Worker.new(pos_x, pos_y, tilemap_data)
	local self = Pawn.new(pos_x, pos_y, tilemap_data)  -- вызываем конструктор родителя
	setmetatable(self, Worker)  -- устанавливаем метатаблицу наследника
	
	return self
end

return Worker