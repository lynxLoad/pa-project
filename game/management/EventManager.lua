local EM = {}

local entity = require("game.entity.entity")

function EM.call_build_event()
    for _, w in pairs(entity.workers) do
        msg.post(w, "build_event")
    end
end

return EM