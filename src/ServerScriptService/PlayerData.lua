local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local store = DataStoreService:GetDataStore("PlayerData_Farm_v1")

-- A function, not a shared table: DEFAULT_DATA has nested arrays
-- (OwnedPets/EquippedPets), and table.clone only copies one level deep -
-- every new player would otherwise mutate the same two shared tables.
local function defaultData()
	return {
		Energy = 0,
		OwnedPets = { "starter" },
		EquippedPets = { "starter" },
	}
end

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

	local data = defaultData()
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
