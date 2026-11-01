local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetTypes = require(ReplicatedStorage.Game.PetTypes)

local PetManager = {}

PetManager.MAX_EQUIPPED = 3

-- userId -> { [petKey] = Model }, the little orbiting companions currently
-- shown for each player. Kept here (not in PlayerData) since these are
-- pure visuals, rebuilt from EquippedPets whenever it changes.
local visuals = {}

function PetManager.Buy(data, petKey)
	local def = PetTypes[petKey]
	if not def then
		return false, "unknown pet"
	end
	if table.find(data.OwnedPets, petKey) then
		return false, "already owned"
	end
	if data.Energy < def.cost then
		return false, "not enough energy"
	end

	data.Energy -= def.cost
	table.insert(data.OwnedPets, petKey)
	return true
end

function PetManager.Equip(data, petKey)
	if not table.find(data.OwnedPets, petKey) then
		return false, "not owned"
	end
	if table.find(data.EquippedPets, petKey) then
		return false, "already equipped"
	end
	if #data.EquippedPets >= PetManager.MAX_EQUIPPED then
		return false, "equip limit reached"
	end

	table.insert(data.EquippedPets, petKey)
	return true
end

function PetManager.Unequip(data, petKey)
	local index = table.find(data.EquippedPets, petKey)
	if not index then
		return false, "not equipped"
	end

	table.remove(data.EquippedPets, index)
	return true
end

-- Total passive energy/sec from every currently equipped pet.
function PetManager.PassiveRate(data)
	local total = 0
	for _, petKey in ipairs(data.EquippedPets) do
		local def = PetTypes[petKey]
		if def then
			total += def.energyPerSec
		end
	end
	return total
end

local function createPetModel(petKey, def)
	local part = Instance.new("Part")
	part.Name = "Pet_" .. petKey
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1.8, 1.8, 1.8)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = def.color or Color3.fromRGB(255, 255, 255)
	part.Parent = workspace

	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromOffset(100, 24)
	label.StudsOffset = Vector3.new(0, 1.6, 0)
	label.AlwaysOnTop = true
	label.Parent = part

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 14
	text.TextStrokeTransparency = 0.4
	text.Text = def.name
	text.Parent = label

	return part
end

-- Rebuilds the set of visible pet models for this player to match
-- data.EquippedPets exactly (adds missing ones, removes stale ones).
function PetManager.SyncVisuals(player, data)
	local owned = visuals[player.UserId]
	if not owned then
		owned = {}
		visuals[player.UserId] = owned
	end

	for petKey, model in pairs(owned) do
		if not table.find(data.EquippedPets, petKey) then
			model:Destroy()
			owned[petKey] = nil
		end
	end

	for _, petKey in ipairs(data.EquippedPets) do
		if not owned[petKey] then
			local def = PetTypes[petKey]
			if def then
				owned[petKey] = createPetModel(petKey, def)
			end
		end
	end
end

function PetManager.ClearVisuals(player)
	local owned = visuals[player.UserId]
	if not owned then
		return
	end
	for _, model in pairs(owned) do
		model:Destroy()
	end
	visuals[player.UserId] = nil
end

-- Orbits every visible pet around its owner's character, one slot per
-- equipped index so they fan out instead of stacking on top of each other.
function PetManager.StepFollow(now)
	for userId, owned in pairs(visuals) do
		local player = game:GetService("Players"):GetPlayerByUserId(userId)
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local index = 0
			for _, model in pairs(owned) do
				index += 1
				local angle = now * 2 + index * (math.pi * 2 / 3)
				local offset = Vector3.new(math.cos(angle) * 4, 2 + math.sin(now * 3 + index) * 0.4, math.sin(angle) * 4)
				model.Position = root.Position + offset
			end
		end
	end
end

return PetManager
