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

local function safeUnit(vector: Vector3, fallback: Vector3): Vector3
	if vector.Magnitude > 0.001 then
		return vector.Unit
	end

	return fallback
end

local function projectOnPlane(vector: Vector3, normal: Vector3): Vector3
	return vector - normal * vector:Dot(normal)
end

--------------------
-- Public Methods --
--------------------

function MovementController.new(parent)
	local self = setmetatable({}, MovementController)

	self.Parent = parent

	self.WalkSpeed = 12

	self.AirControl = 0.4

	self.GroundAcceleration = 80
	self.AirAcceleration = 30

	self.GravityStrength = workspace.Gravity
	self.MaxFallSpeed = 90

	self.JumpPower = 55

	self.CurrentVelocity = Vector3.zero
	self.LastMoveDirection = Vector3.zero

	return self
end

function MovementController:ComputeToVelocity(deltaTime, input, gravityUp, groundInfo, cameraCFrame)
	local isGrounded = groundInfo.IsGrounded
	local groundNormal = groundInfo.Normal

	local gravityDown = -gravityUp

	local rawForward = -cameraCFrame.ZVector
	local forwardProjected = rawForward - gravityUp * rawForward:Dot(gravityUp)

	local forward =
		safeUnit(forwardProjected, self.LastMoveDirection.Magnitude > 0 and self.LastMoveDirection or Vector3.zAxis)
	local right = safeUnit(forward:Cross(gravityUp), Vector3.xAxis)

	local moveDirection = forward * input.Y + right * input.X

	if moveDirection.Magnitude > 0.001 then
		moveDirection = moveDirection.Unit
		self.LastMoveDirection = moveDirection
	else
		moveDirection = Vector3.zero
	end

	local currentVelocity = self.CurrentVelocity

	local verticalSpeed = currentVelocity:Dot(gravityUp)
	local verticalVelocity = gravityUp * verticalSpeed

	local horizontalVelocity = currentVelocity - verticalVelocity

	local targetVelocity = moveDirection * self.WalkSpeed

	if isGrounded and groundNormal then
		targetVelocity = projectOnPlane(targetVelocity, groundNormal)

		if targetVelocity.Magnitude > 0.001 then
			targetVelocity = targetVelocity.Unit * self.WalkSpeed
		end

		horizontalVelocity = projectOnPlane(horizontalVelocity, groundNormal)
	end

	local acceleration = isGrounded and self.GroundAcceleration or self.AirAcceleration
	local control = isGrounded and 1 or self.AirControl

	local delta = targetVelocity - horizontalVelocity
	local maxChange = acceleration * control * deltaTime
	local change = delta.Magnitude > maxChange and delta.Unit * maxChange or delta

	horizontalVelocity += change

	if isGrounded then
		verticalVelocity = gravityDown * 2
	else
		verticalVelocity += gravityDown * self.GravityStrength * deltaTime

		local fallSpeed = verticalVelocity:Dot(gravityDown)

		if fallSpeed > self.MaxFallSpeed then
			verticalVelocity = gravityDown * self.MaxFallSpeed
		end
	end

	self.CurrentVelocity = horizontalVelocity + verticalVelocity

	return self.CurrentVelocity, moveDirection
end
function MovementController:ComputeToForce(input, gravityUp, walkSpeed)
	local cameraForward = workspace.CurrentCamera.CFrame.LookVector
	local forward = (cameraForward - gravityUp * cameraForward:Dot(gravityUp)).Unit
	local right = gravityUp:Cross(forward).Unit

	local moveDirection = (forward * input.Y + right * input.X)

	local targetVelocity = moveDirection * walkSpeed
	local currentVelocity = self.Parent.humanoidRootPart.AssemblyLinearVelocity

	local force = (targetVelocity - currentVelocity) * self.GroundAcceleration
	local horizontalForce = force - (force:Dot(gravityUp) * gravityUp)

	return horizontalForce
end

function MovementController:Jump(gravityUp)
	local horizontalVelocity = self.CurrentVelocity - gravityUp * self.CurrentVelocity:Dot(gravityUp)
	local jumpVelocity = gravityUp * self.JumpPower

	self.CurrentVelocity = horizontalVelocity + jumpVelocity
end

----------------
-- Raw Script --
----------------

return MovementController
