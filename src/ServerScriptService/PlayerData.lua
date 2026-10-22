local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local store = DataStoreService:GetDataStore("PlayerData_v1")

local DEFAULT_DATA = {
	Cash = 0,
	OwnsDoubleCash = false,
	OwnsVIP = false,
}

local cache = {}

local PlayerData = {}

function PlayerData.Load(player)
	local ok, result = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)

	local data = DEFAULT_DATA
	if ok and result then
		data = result
	end

	cache[player.UserId] = data
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
