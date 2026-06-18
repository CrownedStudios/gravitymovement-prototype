--[=[
@class RigSetup
@client
]=]

-- @author drCrowned_lua
-- @date 17/6/2026 (DD/MM/YY)

local RigSetup = {}
RigSetup.__index = RigSetup

function RigSetup.new(parent)
	local self = setmetatable({}, RigSetup)

	self._parent = parent
	self.humanoidRootPart = parent.humanoidRootPart

	self:InitializeRig()

	return self
end

function RigSetup:InitializeRig()
	-- 1. Assemble dynamic Attachment
	local attachment = self.humanoidRootPart:FindFirstChild("GravityAttachment") or Instance.new("Attachment")
	attachment.Name = "GravityAttachment"
	attachment.Parent = self.humanoidRootPart

	-- 2. Clean up old LinearVelocity constraints to stop kinematic overriding
	local oldMover = self.humanoidRootPart:FindFirstChildOfClass("LinearVelocity")
	if oldMover then
		oldMover:Destroy()
	end

	-- 3. Create the foundational VectorForce (For Counter-Gravity and Walking)
	local vectorForce = self.humanoidRootPart:FindFirstChild("GravityForce") or Instance.new("VectorForce")
	vectorForce.Name = "GravityForce"
	vectorForce.Attachment0 = attachment
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.Force = Vector3.zero
	vectorForce.Parent = self.humanoidRootPart
	self.VectorForce = vectorForce

	-- 4. Create the AlignOrientation constraint (For Visual/Physical Leaning)
	local alignOrientation = self.humanoidRootPart:FindFirstChild("GravityAlignment")
		or Instance.new("AlignOrientation")
	alignOrientation.Name = "GravityAlignment"
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.Responsiveness = 25
	alignOrientation.RigidityEnabled = false -- Keeps transitions sleek over loops
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Parent = self.humanoidRootPart
	self.AlignOrientation = alignOrientation
end

function RigSetup:ApplyForces(gravityForce, walkForce, targetCFrame)
	self.VectorForce.Force = gravityForce + walkForce
	self.AlignOrientation.CFrame = targetCFrame
end

return RigSetup
