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

local function createDebugParts(parent)
	if not CollisionController.DebugEnabled then
		return
	end

	local startSphere = Instance.new("Part")
	startSphere.Name = "GroundStart"
	startSphere.Shape = Enum.PartType.Ball
	startSphere.Anchored = true
	startSphere.CanCollide = false
	startSphere.CanQuery = false
	startSphere.CanTouch = false
	startSphere.Material = Enum.Material.Neon
	startSphere.Transparency = 0.5
	startSphere.Parent = parent

	local endSphere = startSphere:Clone()
	endSphere.Name = "GroundEnd"
	endSphere.Parent = parent

	local hitMarker = Instance.new("Part")
	hitMarker.Name = "GroundHit"
	hitMarker.Shape = Enum.PartType.Ball
	hitMarker.Size = Vector3.one * 0.5
	hitMarker.Anchored = true
	hitMarker.CanCollide = false
	hitMarker.CanTouch = false
	hitMarker.CanQuery = false
	hitMarker.Material = Enum.Material.Neon
	hitMarker.Parent = parent

	local normalPart = Instance.new("Part")
	normalPart.Name = "GroundNormal"
	normalPart.Size = Vector3.new(0.2, 0.2, 3)
	normalPart.Anchored = true
	normalPart.CanCollide = false
	normalPart.CanTouch = false
	normalPart.CanQuery = false
	normalPart.Material = Enum.Material.Neon
	normalPart.Parent = parent

	return startSphere, endSphere, hitMarker, normalPart
end

local function makeDebugPart(name, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = Enum.Material.Neon
	part.Transparency = 0.25
	part.Parent = parent

	return part
end

local function drawLine(part, origin, direction, thickness)
	local length = direction.Magnitude

	if length < 0.001 then
		part.Transparency = 1
		return
	end

	part.Size = Vector3.new(thickness, thickness, length)
	part.CFrame = CFrame.lookAt(origin + direction * 0.5, origin + direction)
	part.Transparency = 0.25
end

--------------------
-- Public Methods --
--------------------

function CollisionController.new(parent)
	local self = setmetatable({}, CollisionController)

	self.Parent = parent

	self.GroundDistance = 1.25
	self.SnapDistance = 0.5

	self.SkinWidth = 0.05
	self.MaxSnapSpeed = 16

	-- self.GroundDistance = 0.45
	-- self.SnapDistance = 1.25

	-- self.SkinWidth = 0.08
	-- self.MaxSnapSpeed = 16

	self.GravityProbeDistance = 3

	self.RaycastParams = RaycastParams.new()
	self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.RaycastParams.FilterDescendantsInstances = { self.Parent.character }

	self._debugFolder = workspace["$Components"]:FindFirstChild("CollisionVisualizer")
	if not self._debugFolder then
		self._debugFolder = Instance.new("Folder")
		self._debugFolder.Name = "CollisionVisualizer"
		self._debugFolder.Parent = workspace["$Components"]
	end

	self._debugStartSphere, self._debugEndSphere, self._debugHitMarker, self._debugNormal =
		createDebugParts(self._debugFolder)

	self._debugSampleHits = {}
	self._debugRays = {}
	self._debugRayIndex = 0

	return self
end

function CollisionController:_beginDebugRays()
	if not CollisionController.DebugEnabled then
		return
	end

	self._debugRayIndex = 0
end

function CollisionController:_drawDebugRay(origin, direction, didHit)
	if not CollisionController.DebugEnabled then
		return
	end

	self._debugRayIndex += 1

	local rayPart = self._debugRays[self._debugRayIndex]

	if not rayPart then
		rayPart = makeDebugPart("GravityProbe_" .. tostring(self._debugRayIndex), self._debugFolder)

		self._debugRays[self._debugRayIndex] = rayPart
	end

	drawLine(rayPart, origin, direction, 0.08)

	if didHit then
		rayPart.Transparency = 0.05
	else
		rayPart.Transparency = 0.65
	end
end
function CollisionController:_drawDebugHit(index, position)
	if not CollisionController.DebugEnabled then
		return
	end

	local hitPart = self._debugSampleHits[index]

	if not hitPart then
		hitPart = makeDebugPart("GravityProbeHit_" .. tostring(index), self._debugFolder)

		hitPart.Shape = Enum.PartType.Ball
		hitPart.Size = Vector3.one * 0.25

		self._debugSampleHits[index] = hitPart
	end

	hitPart.Position = position
	hitPart.Transparency = 0.05
end

function CollisionController:_endDebugRays()
	if not CollisionController.DebugEnabled then
		return
	end

	for i = self._debugRayIndex + 1, #self._debugRays do
		self._debugRays[i].Transparency = 1
	end

	if self._debugSampleHits then
		for i = self._debugRayIndex + 1, #self._debugSampleHits do
			self._debugSampleHits[i].Transparency = 1
		end
	end
end

function CollisionController:_isWalkable(normal, gravityUp)
	local slopeDot = normal:Dot(gravityUp)

	local maxSlopeAngle = math.rad(50)
	local minimumDot = math.cos(maxSlopeAngle)

	return slopeDot >= minimumDot
end

function CollisionController:_isGravitySurface(normal, gravityUp)
	local dot = normal:Dot(gravityUp)

	return dot > -0.25
end

function CollisionController:GetSnapVelocity(position, gravityUp, deltaTime)
	local snapInfo = self:GetGroundInfoAt(position, gravityUp, self.SnapDistance)

	if not snapInfo.IsGrounded then
		return Vector3.zero, snapInfo
	end

	local desiredDistance = self.SkinWidth
	local error = snapInfo.Distance - desiredDistance

	local snapVelocity = -gravityUp * (error / deltaTime)

	if snapVelocity.Magnitude > self.MaxSnapSpeed then
		snapVelocity = snapVelocity.Unit * self.MaxSnapSpeed
	end

	return snapVelocity, snapInfo
end

function CollisionController:SweepMovement(position, displacement)
	if displacement.Magnitude < 0.001 then
		return position
	end

	local radius = self.Parent.CharacterRadius

	local result = workspace:Spherecast(position, radius, displacement, self.RaycastParams)

	if not result then
		return position + displacement
	end

	local safeDistance = math.max(0, result.Distance - self.SkinWidth)

	return position + displacement.Unit * safeDistance
end

function CollisionController:GetGroundInfoAt(position, gravityUp, castDistance)
	local sphereCenter = position - gravityUp * (self.Parent.CharacterHeight / 2 - self.Parent.CharacterRadius)

	local radius = self.Parent.CharacterRadius

	local result = workspace:Spherecast(sphereCenter, radius, -gravityUp * castDistance, self.RaycastParams)

	if not result then
		return {
			IsGrounded = false,
			SphereCenter = sphereCenter,
			Radius = radius,
		}
	end

	local isWalkable = self:_isWalkable(result.Normal, gravityUp)

	return {
		IsGrounded = isWalkable,
		Normal = result.Normal,
		Instance = result.Instance,
		Distance = result.Distance,
		Position = result.Position,
		SphereCenter = sphereCenter,
		Radius = radius,
	}
end

function CollisionController:GetGroundInfo(gravityUp)
	return self:GetGroundInfoAt(self.Parent.humanoidRootPart.Position, gravityUp, self.GroundDistance)
end

function CollisionController:GetSurfaceSamples(position, gravityUp)
	self:_beginDebugRays()

	local samples = {}

	local humanoidRootPart = self.Parent.humanoidRootPart
	local radius = self.Parent.CharacterRadius

	local center = position - gravityUp * (self.Parent.CharacterHeight / 2 - self.Parent.CharacterRadius)

	local right = humanoidRootPart.CFrame.RightVector
	local forward = humanoidRootPart.CFrame.LookVector

	right = right - gravityUp * right:Dot(gravityUp)
	forward = forward - gravityUp * forward:Dot(gravityUp)

	if right.Magnitude > 0.001 then
		right = right.Unit
	else
		right = Vector3.xAxis
	end

	if forward.Magnitude > 0.001 then
		forward = forward.Unit
	else
		forward = Vector3.zAxis
	end

	local function addSampleFromRay(origin, direction)
		if direction.Magnitude < 0.001 then
			return
		end

		local result = workspace:Raycast(origin, direction, self.RaycastParams)

		self:_drawDebugRay(origin, direction, result ~= nil)

		if not result then
			return
		end

		if not result.Instance.CanCollide then
			return
		end

		self:_drawDebugHit(self._debugRayIndex, result.Position)

		if not self:_isGravitySurface(result.Normal, gravityUp) then
			return
		end

		table.insert(samples, result)
	end

	-- 1. Downward samples for floors/slopes.
	local offsets = {
		Vector3.zero,
		right * radius * 0.6,
		-right * radius * 0.6,
		forward * radius * 0.6,
		-forward * radius * 0.6,
	}

	for _, offset in ipairs(offsets) do
		addSampleFromRay(center + offset, -gravityUp * self.GravityProbeDistance)
	end

	self:_endDebugRays()
	return samples
end

-- function CollisionController:GetSurfaceSamples(position, gravityUp, desiredDirection)
-- 	local samples = {}

-- 	local humanoidRootPart = self.Parent.humanoidRootPart
-- 	local radius = self.Parent.CharacterRadius

-- 	local center = position - gravityUp * (self.Parent.CharacterHeight / 2 - self.Parent.CharacterRadius)
-- 	local right = humanoidRootPart.CFrame.RightVector
-- 	local forward = humanoidRootPart.CFrame.LookVector

-- 	right = right - gravityUp * right:Dot(gravityUp)
-- 	forward = forward - gravityUp * forward:Dot(gravityUp)

-- 	if right.Magnitude > 0.001 then
-- 		right = right.Unit
-- 	else
-- 		right = Vector3.xAxis
-- 	end

-- 	if forward.Magnitude > 0.001 then
-- 		forward = forward.Unit
-- 	else
-- 		forward = Vector3.zAxis
-- 	end

-- 	local offsets = {
-- 		Vector3.zero,
-- 		right * radius * 0.6,
-- 		-right * radius * 0.6,
-- 		forward * radius * 0.6,
-- 		-forward * radius * 0.6,
-- 	}

-- 	for _, offset in ipairs(offsets) do
-- 		local origin = center + offset

-- 		local result = workspace:Raycast(origin, -gravityUp * self.SnapDistance, self.RaycastParams)

-- 		if result then
-- 			local part = result.Instance
-- 			local validGravityPoints = part:GetAttribute("ValidGravityPoints")
-- 			if not validGravityPoints then
-- 				validGravityPoints = "All"
-- 			elseif validGravityPoints ~= "All" then
-- 				validGravityPoints = string.split(validGravityPoints, ", ")
-- 			end

-- 			-- if
-- 			-- 	(validGravityPoints == "All" or table.find(validGravityPoints, _currentGravityPoint))
-- 			-- 	and (result.Instance.CanCollide and not result.Instance.Parent:FindFirstChild("Humanoid"))
-- 			-- then
-- 			-- 	return result.Normal
-- 			-- end

-- 			--(validGravityPoints == "All" or table.find(validGravityPoints, _currentGravityPoint))

-- 			if self:_isGravitySurface(result.Normal, gravityUp) then
-- 				table.insert(samples, result)
-- 			end
-- 		end
-- 	end

-- 	return samples
-- end

----------------
-- Raw Script --
----------------

return CollisionController
