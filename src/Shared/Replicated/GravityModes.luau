--[=[
Holds gravity modes.

@class GravityModes
]=]

-- @author drCrowned_lua
-- @date 16/6/2026 (DD/MM/YY)

local GravityModes = {
	GravityModes = { "Normal", "Inverse", "Core" },
}

---------------------
-- Local Functions --
---------------------

local function safeUnit(v)
	if v.Magnitude < 0.001 then
		return Vector3.new(0, 1, 0)
	end
	return v.Unit
end

--------------------
-- Public Methods --
--------------------

function GravityModes.Normal()
	return Vector3.new(0, 1, 0)
end

function GravityModes.Inverse()
	return Vector3.new(0, -1, 0)
end

function GravityModes.Core(player, corePart)
	local char = player.Character
	if not char then
		return Vector3.new(0, 1, 0)
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return Vector3.new(0, 1, 0)
	end

	if not corePart then
		return Vector3.new(0, 1, 0)
	end

	-- gravity up = away from core
	return safeUnit(hrp.Position - corePart.Position)
end

----------------
-- Raw Script --
----------------

return GravityModes
