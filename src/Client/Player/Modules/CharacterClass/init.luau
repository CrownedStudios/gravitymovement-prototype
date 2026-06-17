--[=[
Custom character logic and gravity manupulation implementation.
Forked from EgoMoose's Rbx-Gravity-Controller
https://github.com/EgoMoose/Rbx-Gravity-Controller

@class CharacterClass
@client
]=]

-- @author drCrowned_lua
-- @date 16/6/2026 (DD/MM/YY)

local CharacterClass = {}
CharacterClass.__index = CharacterClass

-------------------
-- Game Services --
-------------------

local RunService = game:GetService("RunService")

---------------
-- Variables --
---------------

local UNIT_Y = Vector3.new(0, 1, 0)

---------------------
-- Local Functions --
---------------------

--------------------
-- Public Methods --
--------------------

function CharacterClass.new(player: Player)
	local self = setmetatable({}, CharacterClass)

	self.player = player
	self.character = player.Character or player.CharacterAdded:Wait()
	self.humanoid = self.Character:WaitForChild("Humanoid")
	self.humanoidRootPart = self.Character.PrimaryPart
end

----------------
-- Raw Script --
----------------

return CharacterClass
