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

local function getAverageNormal(samples)
	if #samples == 0 then
		return nil
	end

	local normalSum = Vector3.zero

	for _, sample in ipairs(samples) do
		normalSum += sample.Normal
	end

	if normalSum.Magnitude < 0.001 then
		return nil
	end

	return normalSum.Unit
end

--------------------
-- Public Methods --
--------------------

function GravityController.new(parent)
	local self = setmetatable({}, GravityController)

	self.Parent = parent

	local attachment = Instance.new("Attachment")
	attachment.Parent = self.Parent.humanoidRootPart

	local align = Instance.new("AlignOrientation")
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.Responsiveness = 40
	align.RigidityEnabled = true
	align.Parent = self.Parent.humanoidRootPart

	self._orientation = align
	self._lastDirection = Vector3.zAxis

	self.TargetGravityUp = self.Parent._gravityUp
	self.GravitySmoothSpeed = 12

	return self
end

function GravityController:_update(gravityUp, desiredDirection)
	local targetCFrame

	if InputWrapperController.MouseLocked then
		local cameraForward = workspace.CurrentCamera.CFrame.LookVector

		local projected = cameraForward - gravityUp * cameraForward:Dot(gravityUp)

		if projected.Magnitude > 0.001 then
			self._lastDirection = projected.Unit
		end
	elseif desiredDirection.Magnitude > 0.001 then
		self._lastDirection = desiredDirection.Unit
	end

	local forward = self._lastDirection
	local right = forward:Cross(gravityUp)

	if right.Magnitude < 0.001 then
		right = Vector3.xAxis
	else
		right = right.Unit
	end

	forward = gravityUp:Cross(right).Unit

	targetCFrame = CFrame.fromMatrix(self.Parent.humanoidRootPart.Position, right, gravityUp, -forward)

	self._orientation.CFrame = targetCFrame
end

function GravityController:StepGravity(deltaTime)
	local samples =
		self.Parent.CollisionController:GetSurfaceSamples(self.Parent.humanoidRootPart.Position, self.Parent._gravityUp)

	local averageNormal = getAverageNormal(samples)
	if averageNormal then
		self.TargetGravityUp = averageNormal
	end

	local alpha = 1 - math.exp(-self.GravitySmoothSpeed * deltaTime)

	return self.Parent._gravityUp:Lerp(self.TargetGravityUp, alpha).Unit
end

----------------
-- Raw Script --
----------------

return GravityController
