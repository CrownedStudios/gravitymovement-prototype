--[=[
@class CollisionController
@client
]=]

-- @author drCrowned_lua
-- @date 17/6/2026 (DD/MM/YY)

local CollisionController = {
	DebugEnabled = true,
}
CollisionController.__index = CollisionController

---------------------
-- Local Functions --
---------------------

local function createDebugPart(name, parent, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = Enum.Material.Neon
	part.Color = color or Color3.fromRGB(0, 255, 0)
	part.Transparency = 0.4
	part.Parent = parent
	return part
end

local function drawLine(part, origin, target, thickness)
	local direction = target - origin
	local length = direction.Magnitude
	if length < 0.001 then
		part.Transparency = 1
		return
	end
	part.Size = Vector3.new(thickness, thickness, length)
	part.CFrame = CFrame.lookAt(origin + direction * 0.5, target)
	part.Transparency = 0.4
end

--------------------
-- Public Methods --
--------------------

function CollisionController.new(parent)
	local self = setmetatable({}, CollisionController)

	self._parent = parent

	self.character = parent.character
	self.radius = parent.CharacterRadius

	self.GroundCheckDistance = 3.5
	self.SmoothSpeed = 15

	self._currentGravityUp = Vector3.new(0, 1, 0)

	self._raycastParams = RaycastParams.new()
	self._raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self._raycastParams.FilterDescendantsInstances = { self.character }

	if CollisionController.DebugEnabled then
		self._debugFolder = workspace["$Components"]:FindFirstChild("CollisionVisualizer") or Instance.new("Folder")
		self._debugFolder.Name = "CollisionVisualizer"
		self._debugFolder.Parent = workspace

		self._rayVisualizers = {}
		self._hitVisualizers = {}

		self._mainArrow = createDebugPart("MainGravityUp", self._debugFolder, Color3.fromRGB(0, 255, 255))
	end

	return self
end

function CollisionController:_getAverageNormal(rootCFrame)
	local origin = rootCFrame.Position

	local right = rootCFrame.RightVector
	local forward = rootCFrame.LookVector

	right = (right - self._currentGravityUp * right:Dot(self._currentGravityUp))
	forward = (forward - self._currentGravityUp * forward:Dot(self._currentGravityUp))

	right = right.Magnitude > 0.001 and right.Unit or Vector3.xAxis
	forward = forward.Magnitude > 0.001 and forward.Unit or Vector3.zAxis

	local offsets = {
		Vector3.zero, -- center
		right * self.radius, -- right
		-right * self.radius, -- left
		forward * self.radius, -- front
		-forward * self.radius, -- back
	}

	local normalSum = Vector3.zero
	local hitCount = 0

	for i, offset in ipairs(offsets) do
		local rayOrigin = origin + offset
		local rayDirection = -self._currentGravityUp * self.GroundCheckDistance
		local rayTarget = rayOrigin + rayDirection

		local result = workspace:Raycast(rayOrigin, rayDirection, self._raycastParams)

		if CollisionController.DebugEnabled then
			if not self._rayVisualizers[i] then
				self._rayVisualizers[i] = createDebugPart("Ray_" .. i, self._debugFolder, Color3.fromRGB(255, 100, 0))
				self._hitVisualizers[i] = createDebugPart("Hit_" .. i, self._debugFolder, Color3.fromRGB(255, 255, 0))
				self._hitVisualizers[i].Shape = Enum.PartType.Ball
				self._hitVisualizers[i].Size = Vector3.new(0.3, 0.3, 0.3)
			end

			drawLine(self._rayVisualizers[i], rayOrigin, result and result.Position or rayTarget, 0.05)
			if result then
				self._hitVisualizers[i].Position = result.Position
				self._hitVisualizers[i].Transparency = 0.2
			else
				self._hitVisualizers[i].Transparency = 1
			end
		end

		if result then
			normalSum += result.Normal
			hitCount += 1
		end
	end

	if CollisionController.DebugEnabled then
		drawLine(self._mainArrow, origin, origin + self._currentGravityUp * 4, 0.15)
	end

	if hitCount == 0 or normalSum.Magnitude < 0.001 then
		return self._currentGravityUp
	end

	return normalSum.Unit
end

function CollisionController:Step(deltaTime, rootCFrame)
	local targetNormal = self:_getAverageNormal(rootCFrame)

	local alpha = 1 - math.exp(-self.SmoothSpeed * deltaTime)
	self._currentGravityUp = self._currentGravityUp:Lerp(targetNormal, alpha).Unit

	return self._currentGravityUp
end

----------------
-- Raw Script --
----------------

return CollisionController
