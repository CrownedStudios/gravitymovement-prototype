local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GravityModes = require(ReplicatedStorage.Gravity.GravityModes)
local GravityChange = ReplicatedStorage:WaitForChild("Network"):WaitForChild("GravityChange")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local corePart = workspace:WaitForChild("TestMap"):WaitForChild("Core")

local currentMode = "Normal"
local gravityUp = Vector3.new(0, 1, 0)

local function getGravityUp()
	if currentMode == "Core" then
		return GravityModes.Core(player, corePart)
	end

	return GravityModes[currentMode]()
end

GravityChange.OnClientEvent:Connect(function(mode)
	currentMode = mode
end)

RunService.RenderStepped:Connect(function()
	local target = getGravityUp()

	-- smooth interpolation (important or physics feels like a broken elevator)
	gravityUp = gravityUp:Lerp(target, 0.1).Unit

	-- APPLY GRAVITY
	local mass = hrp.AssemblyMass
	local gravityForce = workspace.Gravity * mass

	local forceDir = Vector3.new(0, 1, 0) - gravityUp

	hrp:ApplyImpulse(forceDir * gravityForce * RunService.RenderStepped:Wait())
end)
