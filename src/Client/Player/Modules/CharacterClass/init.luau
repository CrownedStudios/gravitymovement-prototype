--[=[
Custom character logic and gravity manipulation implementation.
Inspired by EgoMoose's Rbx-Gravity-Controller and devdump's Gravity Controller
https://github.com/EgoMoose/Rbx-Gravity-Controller
https://www.youtube.com/watch?v=zmGX-vR0Er8&t=98s

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

local RigSetup = require(script.RigSetup)
local CollisionController = require(script.CollisionController)

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

	self.CharacterRadius = 1.5
	self.CharacterHeight = 5

	self.Rig = RigSetup.new(self)
	self.CollisionController = CollisionController.new(self)

	self.LastMoveDirection = Vector3.zAxis
	self.WalkSpeed = 16
	self.AccelerationFactor = 140

	self:_init()

	return self
end

function CharacterClass:_init()
	self.humanoid.AutoRotate = false
	self.humanoid.PlatformStand = true

	self._maid:GiveTask(RunService.Heartbeat:Connect(function(deltaTime)
		self:_update(deltaTime)
	end))
end

function CharacterClass:_update(deltaTime)
	local input = InputWrapperController:GetMoveInput()

	local rootCFrame = self.humanoidRootPart.CFrame
	local cameraCF = workspace.CurrentCamera.CFrame

	-- 1. Run the Surface sensor to calculate our smooth local gravity normal
	local gravityUp = self.CollisionController:Step(deltaTime, rootCFrame)

	-- 2. Dynamically extract structural Mass across the model
	local totalMass = getModelMass(self.character)

	-- 3. Calculate Counter-Gravity Equation to cancel out workspace pulling forces
	local gConstant = workspace.Gravity
	local baseGlobalGravity = Vector3.new(0, -gConstant, 0)
	local customSurfaceGravity = -gravityUp * gConstant

	-- Force = Mass * Acceleration (Target minus Default)
	local gravityForce = totalMass * (customSurfaceGravity - baseGlobalGravity)

	-- 4. Calculate relative spatial movement vectors based on Camera mapping
	local cameraForward = cameraCF.ZVector
	local flatForward = (cameraForward - gravityUp * cameraForward:Dot(gravityUp))

	local forward = flatForward.Magnitude > 0.001 and flatForward.Unit or -rootCFrame.ZVector
	local right = gravityUp:Cross(forward).Unit

	local desiredMoveDirection = (forward * input.Y + right * input.X)
	if desiredMoveDirection.Magnitude > 0.001 then
		desiredMoveDirection = desiredMoveDirection.Unit
		self.LastMoveDirection = desiredMoveDirection
	else
		desiredMoveDirection = Vector3.zero
	end

	-- 5. Calculate physical Walk Forces needed to attain Target Velocity
	local currentVelocity = self.humanoidRootPart.AssemblyLinearVelocity
	local targetVelocity = desiredMoveDirection * self.WalkSpeed

	-- Strip out the vertical component from current velocity to isolate alignment mapping
	local horizontalVelocity = currentVelocity - (currentVelocity:Dot(gravityUp) * gravityUp)

	local velocityDelta = targetVelocity - horizontalVelocity
	local walkForce = velocityDelta * totalMass * (self.AccelerationFactor * deltaTime)

	-- Anti-Slide Clamp: If player is standing completely still, actively cancel sliding momentum
	if desiredMoveDirection.Magnitude < 0.001 then
		walkForce = -horizontalVelocity * totalMass * 25
	end

	-- 6. Map Target Alignment Matrix for AlignOrientation constraint
	local targetCFrame = CFrame.fromMatrix(rootCFrame.Position, right, gravityUp, -forward)

	-- 7. Apply the clean forces directly into our physics setup
	self.Rig:ApplyForces(gravityForce, walkForce, targetCFrame)
end

function CharacterClass:Destroy()
	self.humanoid.PlatformStand = false
	self.humanoid.AutoRotate = true

	self._maid:DoCleaning()
end

----------------
-- Raw Script --
----------------

return CharacterClass
