-- game_events.lua
local event = require("event.event")
local M = {}

M.window_resized = event.create()

return M