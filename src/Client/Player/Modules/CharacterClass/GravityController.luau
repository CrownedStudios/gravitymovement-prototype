--[=[
@class GravityController
@client
]=]

-- @author drCrowned_lua
-- @date 17/6/2026 (DD/MM/YY)

local GravityController = {
	DebugEnabled = false,
}
GravityController.__index = GravityController

-------------------
-- Game Services --
-------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------
-- Dependencies --
------------------

local import = require(ReplicatedStorage.Packages.import)

local InputWrapperController = import("Controllers/InputWrapperController")

---------------------
-- Local Functions --
---------------------

--------------------
-- Public Methods --
--------------------

function GravityController.new(parent)
	local self = setmetatable({}, GravityController)

	self.Parent = parent

	return self
end

----------------
-- Raw Script --
----------------

return GravityController
