local players = game:GetService("Players")

local player = players.LocalPlayer

local characterclass = require(player.PlayerScripts.Client.Modules.CharacterClass)

characterclass.new(player)
