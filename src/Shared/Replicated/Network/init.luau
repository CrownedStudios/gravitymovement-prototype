--[=[
Defines networking for the game.

@class Network
]=]

-- @author drCrowned_lua
-- @date 16/6/2026 (DD/MM/YY)

local Network = {}

-------------------
-- Game Services --
-------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------
-- Dependencies --
------------------

local import = require(ReplicatedStorage.Packages.import)

local net = import("Packages/Net") ---@module Packages/Net

local types: Folder = import("@/Types")

----------------
-- Raw Script --
----------------

for _, module in next, types:GetChildren() do
	Network[module.Name] = net.Definitions.Namespace(require(module)(net))
end
Network = net.CreateDefinitions(Network)

return Network
