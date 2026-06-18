local InputWrapperController = {
	DebugEnabled = false,

	MouseLocked = false,
}

local UserInputService = game:GetService("UserInputService")

local keyMap = {
	[Enum.KeyCode.W] = Vector2.new(0, 1),
	[Enum.KeyCode.S] = Vector2.new(0, -1),
	[Enum.KeyCode.A] = Vector2.new(-1, 0),
	[Enum.KeyCode.D] = Vector2.new(1, 0),
}

local function getKeyboard()
	local v = Vector2.zero

	for key, vec in pairs(keyMap) do
		if UserInputService:IsKeyDown(key) then
			v += vec
		end
	end

	return v
end

local function getGamepad()
	local state = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)

	local x, y = 0, 0

	for _, input in ipairs(state) do
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			x = input.Position.X
			y = input.Position.Y
		end
	end

	return Vector2.new(x, y)
end

function InputWrapperController:GetMoveInput()
	local keyboard = getKeyboard()
	local gamepad = getGamepad()

	local input = keyboard

	if gamepad.Magnitude > input.Magnitude then
		input = gamepad
	end

	if input.Magnitude > 1 then
		input = input.Unit
	end

	if InputWrapperController.DebugEnabled then
		print("Input:", input)
	end

	return input
end

return InputWrapperController
