local M = {}

function M:init()
	self.root = self:get_node("root")

	self.button = self.druid:new_button("btn", self.on_click)
	self.text = self.druid:new_text("text", "Hello, Druid!")
end

function M:on_click()
	self.text:set_text("The button clicked!")
end

return M