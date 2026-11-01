local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteNames = require(ReplicatedStorage.RemoteNames)
local PetTypes = require(ReplicatedStorage.Game.PetTypes)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateUpdated = remotes:WaitForChild(RemoteNames.STATE_UPDATED)
local openPetShop = remotes:WaitForChild(RemoteNames.OPEN_PET_SHOP)
local buyPet = remotes:WaitForChild(RemoteNames.BUY_PET)
local equipPet = remotes:WaitForChild(RemoteNames.EQUIP_PET)
local unequipPet = remotes:WaitForChild(RemoteNames.UNEQUIP_PET)

-- Pets listed in shop/inventory order.
local PET_ORDER = {}
for key, def in pairs(PetTypes) do
	table.insert(PET_ORDER, key)
end
table.sort(PET_ORDER, function(a, b)
	return PetTypes[a].order < PetTypes[b].order
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- ============================ top stat bar ============================

local statBar = Instance.new("Frame")
statBar.Name = "StatBar"
statBar.Size = UDim2.new(0, 320, 0, 60)
statBar.Position = UDim2.new(0, 10, 0, 10)
statBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
statBar.BackgroundTransparency = 0.25
statBar.Parent = screenGui

local statBarCorner = Instance.new("UICorner")
statBarCorner.CornerRadius = UDim.new(0, 8)
statBarCorner.Parent = statBar

local energyLabel = Instance.new("TextLabel")
energyLabel.Size = UDim2.new(1, -20, 0, 30)
energyLabel.Position = UDim2.new(0, 10, 0, 4)
energyLabel.BackgroundTransparency = 1
energyLabel.TextXAlignment = Enum.TextXAlignment.Left
energyLabel.TextColor3 = Color3.fromRGB(110, 220, 255)
energyLabel.Font = Enum.Font.GothamBold
energyLabel.TextSize = 22
energyLabel.Text = "Energie: 0"
energyLabel.Parent = statBar

local rateLabel = Instance.new("TextLabel")
rateLabel.Size = UDim2.new(1, -20, 0, 20)
rateLabel.Position = UDim2.new(0, 10, 0, 32)
rateLabel.BackgroundTransparency = 1
rateLabel.TextXAlignment = Enum.TextXAlignment.Left
rateLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
rateLabel.Font = Enum.Font.Gotham
rateLabel.TextSize = 14
rateLabel.Text = "+0 /sec (pets)"
rateLabel.Parent = statBar

-- ============================ pet shop popup ============================

local shopOverlay = Instance.new("TextButton")
shopOverlay.Name = "PetShopOverlay"
shopOverlay.Size = UDim2.fromScale(1, 1)
shopOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shopOverlay.BackgroundTransparency = 0.55
shopOverlay.AutoButtonColor = false
shopOverlay.Text = ""
shopOverlay.Visible = false
shopOverlay.ZIndex = 10
shopOverlay.Parent = screenGui

local shopPanel = Instance.new("Frame")
shopPanel.Name = "PetShopPanel"
shopPanel.Size = UDim2.new(0, 380, 0, 420)
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.Position = UDim2.fromScale(0.5, 0.5)
shopPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
shopPanel.ZIndex = 11
shopPanel.Parent = shopOverlay

local shopPanelCorner = Instance.new("UICorner")
shopPanelCorner.CornerRadius = UDim.new(0, 12)
shopPanelCorner.Parent = shopPanel

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 36)
shopTitle.BackgroundTransparency = 1
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 18
shopTitle.Text = "Boutique de Pets (equipe jusqu'a 3)"
shopTitle.ZIndex = 11
shopTitle.Parent = shopPanel

local shopCloseButton = Instance.new("TextButton")
shopCloseButton.Size = UDim2.new(0, 28, 0, 28)
shopCloseButton.Position = UDim2.new(1, -34, 0, 4)
shopCloseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
shopCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopCloseButton.Font = Enum.Font.GothamBold
shopCloseButton.TextSize = 16
shopCloseButton.Text = "X"
shopCloseButton.ZIndex = 12
shopCloseButton.Parent = shopPanel

local shopCloseCorner = Instance.new("UICorner")
shopCloseCorner.CornerRadius = UDim.new(0, 6)
shopCloseCorner.Parent = shopCloseButton

local shopList = Instance.new("ScrollingFrame")
shopList.Size = UDim2.new(1, -20, 1, -50)
shopList.Position = UDim2.new(0, 10, 0, 42)
shopList.BackgroundTransparency = 1
shopList.CanvasSize = UDim2.new(0, 0, 0, 0)
shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopList.ScrollBarThickness = 6
shopList.ZIndex = 11
shopList.Parent = shopPanel

local shopListLayout = Instance.new("UIListLayout")
shopListLayout.Padding = UDim.new(0, 8)
shopListLayout.Parent = shopList

local function closeShop()
	shopOverlay.Visible = false
end

shopCloseButton.MouseButton1Click:Connect(closeShop)
shopOverlay.MouseButton1Click:Connect(closeShop)

local currentState = { Energy = 0, OwnedPets = {}, EquippedPets = {} }
local petRows = {}

local function buildPetRow(petKey)
	local def = PetTypes[petKey]

	local row = Instance.new("Frame")
	row.Name = petKey
	row.Size = UDim2.new(1, 0, 0, 64)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	row.ZIndex = 11
	row.Parent = shopList

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.new(0, 44, 0, 44)
	swatch.Position = UDim2.new(0, 10, 0.5, -22)
	swatch.BackgroundColor3 = def.color
	swatch.ZIndex = 11
	swatch.Parent = row

	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UDim.new(1, 0)
	swatchCorner.Parent = swatch

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -170, 0, 22)
	nameLabel.Position = UDim2.new(0, 64, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.Text = def.name
	nameLabel.ZIndex = 11
	nameLabel.Parent = row

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -170, 0, 18)
	infoLabel.Position = UDim2.new(0, 64, 0, 30)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextSize = 13
	infoLabel.Text = string.format("+%.1f energie/sec", def.energyPerSec)
	infoLabel.ZIndex = 11
	infoLabel.Parent = row

	local actionButton = Instance.new("TextButton")
	actionButton.Size = UDim2.new(0, 90, 0, 36)
	actionButton.Position = UDim2.new(1, -100, 0.5, -18)
	actionButton.Font = Enum.Font.GothamBold
	actionButton.TextSize = 14
	actionButton.TextColor3 = Color3.fromRGB(20, 20, 20)
	actionButton.ZIndex = 11
	actionButton.Parent = row

	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0, 8)
	actionCorner.Parent = actionButton

	actionButton.MouseButton1Click:Connect(function()
		local owned = table.find(currentState.OwnedPets, petKey) ~= nil
		local equipped = table.find(currentState.EquippedPets, petKey) ~= nil

		if not owned then
			buyPet:FireServer(petKey)
		elseif equipped then
			unequipPet:FireServer(petKey)
		else
			equipPet:FireServer(petKey)
		end
	end)

	petRows[petKey] = { row = row, actionButton = actionButton }
end

for _, petKey in ipairs(PET_ORDER) do
	buildPetRow(petKey)
end

local function refreshShop()
	for petKey, entry in pairs(petRows) do
		local def = PetTypes[petKey]
		local owned = table.find(currentState.OwnedPets, petKey) ~= nil
		local equipped = table.find(currentState.EquippedPets, petKey) ~= nil

		if not owned then
			entry.actionButton.Text = def.cost .. " E"
			entry.actionButton.BackgroundColor3 = Color3.fromRGB(90, 200, 120)
		elseif equipped then
			entry.actionButton.Text = "Retirer"
			entry.actionButton.BackgroundColor3 = Color3.fromRGB(220, 120, 90)
		else
			entry.actionButton.Text = "Equiper"
			entry.actionButton.BackgroundColor3 = Color3.fromRGB(110, 170, 230)
		end
	end
end

openPetShop.OnClientEvent:Connect(function()
	shopOverlay.Visible = true
	refreshShop()
end)

-- ============================ state handling ============================

local function applyState(data)
	currentState = data

	energyLabel.Text = "Energie: " .. math.floor(data.Energy)
	rateLabel.Text = string.format("+%.1f /sec (pets)", data.PassiveRate or 0)

	if shopOverlay.Visible then
		refreshShop()
	end
end

stateUpdated.OnClientEvent:Connect(applyState)
