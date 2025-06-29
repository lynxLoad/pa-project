-- spawner.lua
local M = {}

M.positions = {
	vmath.vector3(1,1,0),
	vmath.vector3(1,2,0)
}

function M.init()
	factory.load("/pawns#basefactory", function (self, url, result)
		if not result then
			print("Not instancing")
			return
		end
		factory.create(url, nil, nil, { script_path = hash("/game/pawn/pawn.lua") })
		factory.create(url, nil, nil, { script_path = hash("/game/pawn/pawn.lua") })
	end)
end

function M.register_hooks(wrapper)
	wrapper:register_hook("init", function (self)
		print("test")
	end)
end

return M
