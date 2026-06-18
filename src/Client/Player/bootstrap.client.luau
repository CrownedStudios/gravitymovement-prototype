--[=[
Handles the client-side bootstrap process.

@class bootstrap (Client)
@client
]=]

-- @author drCrowned_lua
-- @date 16/6/2026 (DD/MM/YY)

-------------------
-- Game Services --
-------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------
-- Dependencies --
------------------

local import = require(ReplicatedStorage.Packages.import)

---------------
-- Variables --
---------------

local player = Players.LocalPlayer

local verboseLogging = false
local asyncLoading = false

local loaded = {}
local orderOverride = {}

---------------------
-- Local Functions --
---------------------

local function verbosePrint(...: any)
	if verboseLogging then
		print("[Bootstrapper (Client)]", ...)
	end
end
local function verboseWarn(...: any)
	if verboseLogging then
		warn("[Bootstrapper (Client)]", ...)
	end
end

local function setupLoadedTable(list: { any })
	loaded.loaded = {}
	loaded.initialized = {}
	loaded.started = {}

	for _, i in pairs(list) do
		loaded.loaded[i.Name] = false
	end
end
local function tablePopulated(type: string): boolean
	for name, value in pairs(loaded[type]) do
		if value == false then
			return false
		end
		if not value then
			verboseWarn(`Failed to resolve: {name}`)
			return false
		end
	end
	return true
end

local function load(controller: ModuleScript): { any } | nil
	verbosePrint(("Loading '%s'"):format(controller.Name))

	local startTick, endTick = os.clock(), nil
	local success, message = pcall(function()
		local module = require(controller)
		loaded.loaded[controller.Name] = module

		if module.Init then
			loaded.initialized[controller.Name] = false
		end
		if module.Start then
			loaded.started[controller.Name] = false
		end
	end)
	endTick = os.clock()

	if success then
		verbosePrint(("Loaded '%s' in %s seconds"):format(controller.Name, string.format("%.2f", endTick - startTick)))
		return loaded.loaded[controller.Name]
	else
		verboseWarn(
			("Failed to load '%s', it took %s seconds. Message: %s"):format(
				controller.Name,
				string.format("%.2f", endTick - startTick),
				message
			)
		)
		player:Kick("[Bootstrapper (Client)] Game Load Failure, please rejoin!")
		return nil
	end
end
local function init(controllerData, controllerName: string)
	if not controllerData.Init then
		verbosePrint(("Cannot initialize '%s'"):format(controllerName))
		return
	end

	verbosePrint(("Initializing '%s'"):format(controllerName))

	local startTick, endTick = os.clock(), nil
	local success, message = pcall(function()
		controllerData:Init()
	end)
	endTick = os.clock()

	if success then
		verbosePrint(
			("Initialized '%s' in %s seconds"):format(controllerName, string.format("%.2f", endTick - startTick))
		)
		loaded.initialized[controllerName] = true
	else
		verboseWarn(
			("Failed to initialize '%s', it took %s seconds. Message: %s"):format(
				controllerName,
				string.format("%.2f", endTick - startTick),
				message
			)
		)
		player:Kick("[Bootstrapper (Client)] Game Initialization Failure, please rejoin!")
	end
end
local function start(controllerData, controllerName: string)
	if not controllerData.Start then
		verbosePrint(("Cannot start '%s'"):format(controllerName))
		return
	end

	verbosePrint(("Starting '%s'"):format(controllerName))

	local startTick, endTick = os.clock(), nil
	local success, message = pcall(function()
		controllerData:Start()
	end)
	endTick = os.clock()

	if success then
		verbosePrint(("Started '%s' in %s seconds"):format(controllerName, string.format("%.2f", endTick - startTick)))
		loaded.started[controllerName] = true
	else
		verboseWarn(
			("Failed to start '%s', it took %s seconds. Message: %s"):format(
				controllerName,
				string.format("%.2f", endTick - startTick),
				message
			)
		)
		player:Kick("[Bootstrapper (Client)] Game Start Failure, please rejoin!")
	end
end

----------------
-- Raw Script --
----------------

import.setAliases({
	Controllers = script.Parent.Controllers,
	Modules = script.Parent.Modules,

	Shared = ReplicatedStorage.Shared,
	Packages = ReplicatedStorage.Packages,
})
import.setConfig({
	scriptAlias = "@",
	useWaitForChild = true,
	waitForChildTimeout = 5,
})

local controllers = import("Controllers")
setupLoadedTable(controllers:GetChildren())

verboseWarn("Starting Bootstrapping < Verbose Enabled")

if #orderOverride > 0 then
	verboseWarn("Recived order override, pre-running")

	for _, name in pairs(orderOverride) do
		local module = load(controllers[name])

		if module then
			init(module, name)
			start(module, name)
		else
			verboseWarn(("Failed to pre-run '%s'"):format(name))
			player:Kick("[Bootstrapper (Client)] Game Pre-Run Failure, please rejoin!")
		end
	end
end

if asyncLoading then
	verboseWarn("Beginning Async loading")

	for _, controller in pairs(controllers:GetChildren()) do
		task.defer(load, controller)
	end

	repeat
		task.wait()
	until tablePopulated("loaded")

	verboseWarn("Finished loading, beginning controller initialization")
	for name, _ in pairs(loaded.initialized) do
		task.defer(init, loaded.loaded[name], name)
	end

	repeat
		task.wait()
	until tablePopulated("inited")

	verboseWarn("Finished initializing, beginning controller startup")
	for name, _ in pairs(loaded.started) do
		task.defer(start, loaded.loaded[name], name)
	end

	repeat
		task.wait()
	until tablePopulated("started")

	verboseWarn("Finished Client-Side async loading")
else
	verboseWarn("Beginning lazy loading")

	for _, controller in pairs(controllers:GetChildren()) do
		load(controller)
	end

	verboseWarn("Beginning controller initialization")
	for name, _ in pairs(loaded.initialized) do
		init(loaded.loaded[name], name)
	end

	verboseWarn("Beginning controller startup")
	for name, _ in pairs(loaded.started) do
		start(loaded.loaded[name], name)
	end

	verboseWarn("Finished Client-Side lazy loading")
end

verboseWarn("Finished Bootstrapping < Verbose Enabled")
workspace:SetAttribute("ClientBootstrapped", true)
