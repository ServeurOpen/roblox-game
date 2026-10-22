local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)

local store = DataStoreService:GetDataStore("PlayerData_v2")

local DEFAULT_DATA = {
	Cash = GameConfig.StartingCash,
	OwnsDoubleCash = false,
	OwnsVIP = false,
	PlotIndex = nil,
	GeneratorCount = 0,
}

local cache = {}

local PlayerData = {}

local dataLoadedEvent = Instance.new("BindableEvent")
-- Fires (player, data) once a player's save is loaded and cached. Other
-- server scripts should hook this instead of calling Load themselves, so
-- each player's data is only ever fetched from the DataStore once.
PlayerData.DataLoaded = dataLoadedEvent.Event

function PlayerData.Load(player)
	local ok, result = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)

	local data = table.clone(DEFAULT_DATA)
	if ok and result then
		data = result
	end

	cache[player.UserId] = data
	dataLoadedEvent:Fire(player, data)
	return data
end

function PlayerData.Get(player)
	return cache[player.UserId]
end

function PlayerData.Save(player)
	local data = cache[player.UserId]
	if not data then
		return
	end

	local ok, err = pcall(function()
		store:SetAsync("Player_" .. player.UserId, data)
	end)

	if not ok then
		warn("PlayerData.Save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

function PlayerData.Release(player)
	PlayerData.Save(player)
	cache[player.UserId] = nil
end

Players.PlayerAdded:Connect(function(player)
	PlayerData.Load(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerData.Release(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerData.Save(player)
	end
end)

return PlayerData
