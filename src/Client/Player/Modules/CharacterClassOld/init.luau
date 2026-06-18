--[=[
Custom character logic and gravity manipulation implementation.
Inspired by EgoMoose's Rbx-Gravity-Controller
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

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

------------------
-- Dependencies --
------------------

local import = require(ReplicatedStorage.Packages.import)

local Maid = import("Packages/Maid")

local InputWrapperController = import("Controllers/InputWrapperController")

local CollisionController = require(script.CollisionController)
local MovementController = require(script.MovementController)
local GravityController = require(script.GravityController)

---------------
-- Variables --
---------------

local UNIT_Y = Vector3.new(0, 1, 0)

---------------------
-- Local Functions --
---------------------

local function getModelMass(model)
	local mass = 0
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			mass = mass + part:GetMass()
		end
	end
	return mass
end

--------------------
-- Public Methods --
--------------------

function CharacterClass.new(player: Player)
	local self = setmetatable({}, CharacterClass)

	self._maid = Maid.new()

	self.player = player
	self.character = player.Character or player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
	self.humanoidRootPart = self.character:WaitForChild("HumanoidRootPart")

	self._gravityUp = UNIT_Y
	self._characterMass = 0

	self.CharacterRadius = 1.5
	self.CharacterHeight = 5

	self.CollisionController = CollisionController.new(self)
	self.MovementController = MovementController.new(self)
	self.GravityController = GravityController.new(self)

	self:_init()

	return self
end

function CharacterClass:_init()
	self.humanoid.AutoRotate = false

	self.humanoid.JumpPower = 0
	self.humanoid.JumpHeight = 0

	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

	self._characterMass = getModelMass(self.character)
	self.character.AncestryChanged:Connect(function()
		self._characterMass = getModelMass(self.character)
	end)

	local VectorForce = Instance.new("VectorForce")
	VectorForce.Attachment0 = Instance.new("Attachment", self.humanoidRootPart)
	VectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	VectorForce.Force = Vector3.zero
	VectorForce.Parent = self.humanoidRootPart

	self._maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
		self:_update(dt)
	end))
end

function CharacterClass:_update(deltaTime)
	local input = InputWrapperController:GetMoveInput()

	self._gravityUp = self.GravityController:StepGravity(deltaTime)
	local gravityUp = self._gravityUp

	local characterMass = self._characterMass

	local g = workspace.Gravity
	local gravityForce = g * characterMass * (Vector3.new(0, 1, 0) - gravityUp)

	local movementForce = self.MovementController:ComputeToForce(input, gravityUp, 12)

	self.humanoidRootPart.VectorForce.Force = gravityForce + movementForce

	self.GravityController:_update(gravityUp, self.MovementController.LastMoveDirection)

	-- -- First compute movement using current gravity.
	-- local currentGravityUp = self._gravityUp

	-- local groundInfo = self.CollisionController:GetGroundInfo(currentGravityUp)

	-- local velocity, desiredDirection =
	-- 	self.MovementController:Compute(deltaTime, input, currentGravityUp, groundInfo, workspace.CurrentCamera.CFrame)

	-- -- Then update gravity using desiredDirection.
	-- local gravityUp = self.GravityController:StepGravity(deltaTime, desiredDirection)

	-- -- Re-read ground with updated gravity.
	-- groundInfo = self.CollisionController:GetGroundInfo(gravityUp)

	-- velocity, desiredDirection =
	-- 	self.MovementController:Compute(deltaTime, input, gravityUp, groundInfo, workspace.CurrentCamera.CFrame)

	-- local displacement = velocity * deltaTime
	-- local oldPosition = self.humanoidRootPart.Position

	-- local newPosition = self.CollisionController:SweepMovement(oldPosition, displacement)

	-- local collisionCorrectedVelocity = (newPosition - oldPosition) / deltaTime

	-- local snapVelocity = Vector3.zero
	-- local verticalSpeed = self.MovementController.CurrentVelocity:Dot(gravityUp)

	-- local shouldSnap = groundInfo.IsGrounded and verticalSpeed <= 0.1

	-- if shouldSnap then
	-- 	snapVelocity = self.CollisionController:GetSnapVelocity(newPosition, gravityUp, deltaTime)
	-- end

	-- self.MovementController.CurrentVelocity = collisionCorrectedVelocity

	-- self.humanoidRootPart.AssemblyLinearVelocity = collisionCorrectedVelocity + snapVelocity

	-- self.GravityController:_update(gravityUp, desiredDirection)
end

----------------
-- Raw Script --
----------------

return CharacterClass
