--[=[
Handles the server-side bootstrap process.

@class bootstrap (Server)
@server
]=]

-- @author drCrowned_lua
-- @date 16/6/2026 (DD/MM/YY)

-------------------
-- Game Services --
-------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

------------------
-- Dependencies --
------------------

local import = require(ReplicatedStorage.Packages.import)

---------------
-- Variables --
---------------

local verboseLogging = false
local asyncLoading = false

local loaded = {}

---------------------
-- Local Functions --
---------------------

local function verbosePrint(...: any)
	if verboseLogging then
		print("[Bootstrapper (Server)]", ...)
	end
end
local function verboseWarn(...: any)
	if verboseLogging then
		warn("[Bootstrapper (Server)]", ...)
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

local function load(service: ModuleScript): { any } | nil
	verbosePrint(("Loading '%s'"):format(service.Name))

	local startTick, endTick = os.clock(), nil
	local success, message = pcall(function()
		local module = require(service)
		loaded.loaded[service.Name] = module

		if module.Init then
			loaded.initialized[service.Name] = false
		end
		if module.Start then
			loaded.started[service.Name] = false
		end
	end)
	endTick = os.clock()

	if success then
		verbosePrint(("Loaded '%s' in %s seconds"):format(service.Name, string.format("%.2f", endTick - startTick)))
		return loaded.loaded[service.Name]
	else
		verboseWarn(
			("Failed to load '%s', it took %s seconds. Message: %s"):format(
				service.Name,
				string.format("%.2f", endTick - startTick),
				message
			)
		)
		for _, plr in game:GetService("Players"):GetPlayers() do
			plr:Kick("[Bootstrapper (Server)] Server Load Failure, please rejoin!")
		end
		return nil
	end
end
local function init(serviceData, serviceName: string)
	if not serviceData.Init then
		verbosePrint(("Cannot initialize '%s'"):format(serviceName))
		return
	end

	verbosePrint(("Initializing '%s'"):format(serviceName))

	local startTick, endTick = os.clock(), nil
	local success, message = pcall(function()
		serviceData:Init()
	end)
	endTick = os.clock()

	if success then
		verbosePrint(("Initialized '%s' in %s seconds"):format(serviceName, string.format("%.2f", endTick - startTick)))
		loaded.initialized[serviceName] = true
	else
		verboseWarn(
			("Failed to initialize '%s', it took %s seconds. Message: %s"):format(
				serviceName,
				string.format("%.2f", endTick - startTick),
				message
			)
		)
		for _, plr in game:GetService("Players"):GetPlayers() do
			plr:Kick("[Bootstrapper (Server)] Server Initialization Failure, please rejoin!")
		end
	end
end
local function start(serviceData, serviceName: string)
	if not serviceData.Start then
		verbosePrint(("Cannot start '%s'"):format(serviceName))
		return
	end

	verbosePrint(("Starting '%s'"):format(serviceName))

	local startTick, endTick = os.clock(), nil
	local success, message = pcall(function()
		serviceData:Start()
	end)
	endTick = os.clock()

	if success then
		verbosePrint(("Started '%s' in %s seconds"):format(serviceName, string.format("%.2f", endTick - startTick)))
		loaded.started[serviceName] = true
	else
		verboseWarn(
			("Failed to start '%s', it took %s seconds. Message: %s"):format(
				serviceName,
				string.format("%.2f", endTick - startTick),
				message
			)
		)
		for _, plr in game:GetService("Players"):GetPlayers() do
			plr:Kick("[Bootstrapper (Server)] Server Start Failure, please rejoin!")
		end
	end
end

----------------
-- Raw Script --
----------------

import.setAliases({
	Services = ServerScriptService.Server.Services,
	Modules = ServerScriptService.Server.Modules,

	ServerShared = ServerStorage.ServerShared,
	Shared = ReplicatedStorage.Shared,
	Packages = ReplicatedStorage.Packages,
})
import.setConfig({
	scriptAlias = "@",
	useWaitForChild = true,
	waitForChildTimeout = 3,
})

local services = import("Services")
setupLoadedTable(services:GetChildren())

verboseWarn("Starting Bootstrapping < Verbose Enabled")

if asyncLoading then
	verboseWarn("Beginning Async loading")

	for _, service in pairs(services:GetChildren()) do
		task.defer(load, service)
	end

	repeat
		task.wait()
	until tablePopulated("loaded")

	verboseWarn("Finished loading, beginning service initialization")
	for name, _ in pairs(loaded.initialized) do
		task.defer(init, loaded.loaded[name], name)
	end

	repeat
		task.wait()
	until tablePopulated("inited")

	verboseWarn("Finished initializing, beginning service startup")
	for name, _ in pairs(loaded.started) do
		task.defer(start, loaded.loaded[name], name)
	end

	repeat
		task.wait()
	until tablePopulated("started")

	verboseWarn("Finished Server-Side async loading")
else
	verboseWarn("Beginning lazy loading")

	for _, service in pairs(services:GetChildren()) do
		load(service)
	end

	verboseWarn("Beginning service initialization")
	for name, _ in pairs(loaded.initialized) do
		init(loaded.loaded[name], name)
	end

	verboseWarn("Beginning service startup")
	for name, _ in pairs(loaded.started) do
		start(loaded.loaded[name], name)
	end

	verboseWarn("Finished Server-Side lazy loading")
end

verboseWarn("Finished Bootstrapping < Verbose Enabled")
workspace:SetAttribute("ServerBootstrapped", true)
