local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteNames = require(ReplicatedStorage.RemoteNames)
local PlayerData = require(script.Parent.PlayerData)
local PetManager = require(script.Parent.Game.PetManager)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateUpdated = remotes:WaitForChild(RemoteNames.STATE_UPDATED)
local clickCore = remotes:WaitForChild(RemoteNames.CLICK_CORE)
local openPetShop = remotes:WaitForChild(RemoteNames.OPEN_PET_SHOP)
local buyPet = remotes:WaitForChild(RemoteNames.BUY_PET)
local equipPet = remotes:WaitForChild(RemoteNames.EQUIP_PET)
local unequipPet = remotes:WaitForChild(RemoteNames.UNEQUIP_PET)

local CLICK_VALUE = 1
local CLICK_COOLDOWN = 0.1 -- minimum seconds between accepted clicks, anti-spam

local lastClickAt = {}

local function pushState(player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	stateUpdated:FireClient(player, {
		Energy = data.Energy,
		OwnedPets = data.OwnedPets,
		EquippedPets = data.EquippedPets,
		PassiveRate = PetManager.PassiveRate(data),
	})
end

-- ============================ player lifecycle ============================

local function onDataLoaded(player, data)
	PetManager.SyncVisuals(player, data)
	pushState(player)
end

PlayerData.DataLoaded:Connect(onDataLoaded)

-- Catch up on anyone whose data finished loading before the connection
-- above was made (e.g. the local test player in Studio).
for _, player in ipairs(Players:GetPlayers()) do
	local data = PlayerData.Get(player)
	if data then
		onDataLoaded(player, data)
	end
end

Players.PlayerRemoving:Connect(function(player)
	PetManager.ClearVisuals(player)
	lastClickAt[player.UserId] = nil
end)

-- ============================ energy core ============================

local map = Workspace:WaitForChild("Map")
local core = map:WaitForChild("EnergyCore")
local clickDetector = core:WaitForChild("ClickDetector")

clickDetector.MouseClick:Connect(function(player)
	local now = os.clock()
	if (lastClickAt[player.UserId] or 0) + CLICK_COOLDOWN > now then
		return
	end
	lastClickAt[player.UserId] = now

	local data = PlayerData.Get(player)
	if not data then
		return
	end

	data.Energy += CLICK_VALUE
	pushState(player)
end)

-- Older clients (or anything sending via the remote instead of the click
-- detector) land here too; same cooldown table, same effect.
clickCore.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if (lastClickAt[player.UserId] or 0) + CLICK_COOLDOWN > now then
		return
	end
	lastClickAt[player.UserId] = now

	local data = PlayerData.Get(player)
	if not data then
		return
	end

	data.Energy += CLICK_VALUE
	pushState(player)
end)

-- ============================ pet shop ============================

local shop = map:WaitForChild("PetShop")
local shopPrompt = shop:WaitForChild("ShopPrompt")

shopPrompt.Triggered:Connect(function(player)
	openPetShop:FireClient(player)
end)

buyPet.OnServerEvent:Connect(function(player, petKey)
	if type(petKey) ~= "string" then
		return
	end
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	local ok = PetManager.Buy(data, petKey)
	if ok then
		pushState(player)
	end
end)

equipPet.OnServerEvent:Connect(function(player, petKey)
	if type(petKey) ~= "string" then
		return
	end
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	local ok = PetManager.Equip(data, petKey)
	if ok then
		PetManager.SyncVisuals(player, data)
		pushState(player)
	end
end)

unequipPet.OnServerEvent:Connect(function(player, petKey)
	if type(petKey) ~= "string" then
		return
	end
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	local ok = PetManager.Unequip(data, petKey)
	if ok then
		PetManager.SyncVisuals(player, data)
		pushState(player)
	end
end)

-- ============================ main loop ============================

local passiveAccumulator = 0

RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	PetManager.StepFollow(now)

	passiveAccumulator += dt
	if passiveAccumulator >= 1 then
		passiveAccumulator -= 1
		for _, player in ipairs(Players:GetPlayers()) do
			local data = PlayerData.Get(player)
			if data then
				local rate = PetManager.PassiveRate(data)
				if rate > 0 then
					data.Energy += rate
					pushState(player)
				end
			end
		end
	end
end)
