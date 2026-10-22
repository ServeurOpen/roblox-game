local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteNames = require(ReplicatedStorage.RemoteNames)
local GameConfig = require(ReplicatedStorage.GameConfig)
local PlayerData = require(ServerScriptService.PlayerData)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local cashUpdated = remotes:WaitForChild(RemoteNames.CASH_UPDATED)
local getPlayerData = remotes:WaitForChild(RemoteNames.GET_PLAYER_DATA)

local function addCash(player, amount)
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	data.Cash += amount
	cashUpdated:FireClient(player, data.Cash)
end

getPlayerData.OnServerInvoke = function(player)
	local data = PlayerData.Get(player)
	return data and data.Cash or 0
end

Players.PlayerAdded:Connect(function(player)
	local data = PlayerData.Load(player)
	cashUpdated:FireClient(player, data.Cash)
end)

-- Passive cash generation loop. Replace with real tycoon-plot income later.
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local data = PlayerData.Get(player)
			if data then
				local rate = GameConfig.BaseCashPerSecond
				if data.OwnsDoubleCash then
					rate *= 2
				end
				addCash(player, rate)
			end
		end
	end
end)
