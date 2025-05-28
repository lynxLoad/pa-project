local M = {}

local game_events = require("management.game_events")
local event = require("event.event")

function M:init()
	self.root = self:get_node("root")

	self.check_btn = self.druid:new_button("check_btn", self.on_click)
	self.check_btn.on_hold_callback:subscribe(self.on_hold_callback)
	self.hover = self.druid:new_hover("check_btn", self.on_hover_callback, self.on_mouse_hover_callback)
	
	self.text = self.druid:new_text("text", "Hello, Druid!")

	self.active = false
	self.on_active = event.create()
	self.on_active:trigger(self.active)
end

function M:on_click()
	self.text:set_text("The button clicked!")
	self.active = not self.active
	self.on_active:trigger(self.active)
end

function M:on_hold_callback()
	self.text:set_text("The button clicked!")
end

function M:on_hover_callback()
	--print(self.hover:is_hovered())
end

function M:on_mouse_hover_callback()
	--game_events.is_ui_mouse_hovered = self.hover:is_mouse_hovered()
end

return M