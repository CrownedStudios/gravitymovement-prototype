--[=[
@class MovementController
@client
]=]

-- @author drCrowned_lua
-- @date 17/6/2026 (DD/MM/YY)

local MovementController = {}
MovementController.__index = MovementController

---------------------
-- Local Functions --
---------------------

--------------------
-- Public Methods --
--------------------

function MovementController.new(parent)
	local self = setmetatable({}, MovementController)

	self.Parent = parent

	return self
end

----------------
-- Raw Script --
----------------

return MovementController
