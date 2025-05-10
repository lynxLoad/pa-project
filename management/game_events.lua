-- game_events.lua
local event = require("event.event")
local M = {}

M.is_ui_mouse_hovered = false
M.window_resized = event.create()
M.map_initialized = event.create()

return M