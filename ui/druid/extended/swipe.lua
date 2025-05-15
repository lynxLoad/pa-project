local event = require("event.event")
local const = require("ui.druid.const")
local helper = require("ui.druid.helper")
local component = require("ui.druid.component")

---@class druid.swipe.style
---@field SWIPE_TIME number|nil Maximum time for swipe trigger. Default: 0.4
---@field SWIPE_THRESHOLD number|nil Minimum distance for swipe trigger. Default: 50
---@field SWIPE_TRIGGER_ON_MOVE boolean|nil If true, trigger on swipe moving, not only release action. Default: false

---The component to manage swipe events over a node
---@class druid.swipe: druid.component
---@field node node The node to manage the swipe
---@field on_swipe event fun(context, side, dist, dt) The event triggered when a swipe is detected
---@field style druid.swipe.style The style of the swipe
---@field click_zone node The click zone of the swipe
---@field private _trigger_on_move boolean True if the swipe should trigger on move
---@field private _swipe_start_time number The time the swipe started
---@field private _start_pos vector3 The start position of the swipe
---@field private _is_enabled boolean True if the swipe is enabled
---@field private _is_mobile boolean True if the swipe is on a mobile device
local M = component.create("swipe")


---@param node_or_node_id node|string
---@param on_swipe_callback function
function M:init(node_or_node_id, on_swipe_callback)
	self._trigger_on_move = self.style.SWIPE_TRIGGER_ON_MOVE
	self.node = self:get_node(node_or_node_id)

	self._swipe_start_time = 0
	self._start_pos = vmath.vector3(0)

	self.click_zone = nil
	self.on_swipe = event.create(on_swipe_callback)
end


---@private
function M:on_late_init()
	if not self.click_zone then
		local stencil_node = helper.get_closest_stencil_node(self.node)
		if stencil_node then
			self:set_click_zone(stencil_node)
		end
	end
end


---@private
---@param style druid.swipe.style
function M:on_style_change(style)
	self.style = {
		SWIPE_TIME = style.SWIPE_TIME or 0.4,
		SWIPE_THRESHOLD = style.SWIPE_THRESHOLD or 50,
		SWIPE_TRIGGER_ON_MOVE = style.SWIPE_TRIGGER_ON_MOVE or false,
	}
end


---@private
---@param action_id hash The action id
---@param action action The action table
---@return boolean is_consumed True if the input was consumed
function M:on_input(action_id, action)
	if action_id ~= const.ACTION_TOUCH then
		return false
	end

	if not gui.is_enabled(self.node, true) then
		return false
	end

	local is_pick = helper.pick_node(self.node, action.x, action.y, self.click_zone)
	if not is_pick then
		self:_reset_swipe()
		return false
	end

	if self._swipe_start_time ~= 0 and (self._trigger_on_move or action.released) then
		self:_check_swipe(action)
	end

	if action.pressed then
		self:_start_swipe(action)
	end

	if action.released then
		self:_reset_swipe()
	end

	return true
end


---@private
function M:on_input_interrupt()
	self:_reset_swipe()
end


---Set the click zone for the swipe, useful for restricting events outside stencil node
---@param zone node|string|nil Gui node
function M:set_click_zone(zone)
	if not zone then
		self.click_zone = nil
		return
	end

	self.click_zone = self:get_node(zone)
end


---Start swipe event
---@param action action The action table
function M:_start_swipe(action)
	self._swipe_start_time = socket.gettime()
	self._start_pos.x = action.x
	self._start_pos.y = action.y
end


---Reset swipe event
function M:_reset_swipe()
	self._swipe_start_time = 0
end


---Check swipe event
---@param self druid.swipe
---@param action action
function M:_check_swipe(action)
	local dx = action.x - self._start_pos.x
	local dy = action.y - self._start_pos.y
	local dist = helper.distance(self._start_pos.x, self._start_pos.y, action.x, action.y)
	local delta_time = socket.gettime() - self._swipe_start_time
	local is_swipe = self.style.SWIPE_THRESHOLD <= dist and delta_time <= self.style.SWIPE_TIME

	if is_swipe then
		local is_x_swipe = math.abs(dx) >= math.abs(dy)
		local swipe_side = "undefined"

		if is_x_swipe and dx > 0 then
			swipe_side = "right"
		end
		if is_x_swipe and dx < 0 then
			swipe_side = "left"
		end
		if not is_x_swipe and dy > 0 then
			swipe_side = "up"
		end
		if not is_x_swipe and dy < 0 then
			swipe_side = "down"
		end

		self.on_swipe:trigger(self:get_context(), swipe_side, dist, delta_time)
		self:_reset_swipe()
	end
end


return M
