--[=[
Handles server-side gravity changes.

@class GravityService
@server
]=]

-- @author drCrowned_lua
-- @date 16/6/2026 (DD/MM/YY)

local GravityService = {
	ModeChangeCooldown = 8,
}

-------------------
-- Game Services --
-------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------
-- Dependencies --
------------------

local import = require(ReplicatedStorage.Packages.import)

local Network = import("Shared/Network") ---@module src/Shared/Replicated/Network

local GravityModes = import("Shared/GravityModes") ---@module src/Shared/Replicated/GravityModes

---------------
-- Variables --
---------------

local gravityNetwork = Network.Server:GetNamespace("Gravity")

local modes = GravityModes.GravityModes
local current = modes[1]

--------------------
-- Public Methods --
--------------------

function GravityService:SetGravityMode(newMode)
	local mode = newMode or modes[math.random(#modes)]

	if mode == current then
		GravityService:SetGravityMode()
		return
	end
	current = mode
	gravityNetwork:Get("GravityChange"):SendToAllPlayers(current)
end

----------------
-- Raw Script --
----------------

task.spawn(function()
	while true do
		task.wait(GravityService.ModeChangeCooldown)
		GravityService:SetGravityMode()
	end
end)

return GravityService
