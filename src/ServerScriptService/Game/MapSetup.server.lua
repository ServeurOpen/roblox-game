-- Builds the whole playable area once, synchronously, at server start.
-- Small single shared map for v1: everyone farms the same Energy Core and
-- pet shop (no per-player plots yet - that's an easy later addition once
-- the core loop is proven out, same approach as arenas were for the
-- previous Tower Defense prototype).
local Workspace = game:GetService("Workspace")

local function buildMap()
	local existing = Workspace:FindFirstChild("Map")
	if existing then
		existing:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = Workspace

	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = Vector3.new(120, 1, 120)
	ground.Anchored = true
	ground.Material = Enum.Material.Grass
	ground.Color = Color3.fromRGB(70, 150, 80)
	ground.Position = Vector3.new(0, 0, 0)
	ground.Parent = map

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Anchored = true
	spawn.Material = Enum.Material.WoodPlanks
	spawn.Color = Color3.fromRGB(150, 110, 70)
	spawn.Position = Vector3.new(0, 1, 45)
	spawn.Duration = 0
	spawn.Parent = map

	-- ============================ energy core ============================

	local core = Instance.new("Part")
	core.Name = "EnergyCore"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(10, 10, 10)
	core.Anchored = true
	core.CanCollide = true
	core.Material = Enum.Material.Neon
	core.Color = Color3.fromRGB(110, 220, 255)
	core.Position = Vector3.new(0, 6, 0)
	core.Parent = map

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 16
	clickDetector.Parent = core

	local coreLabel = Instance.new("BillboardGui")
	coreLabel.Name = "CoreLabel"
	coreLabel.Size = UDim2.fromOffset(200, 40)
	coreLabel.StudsOffset = Vector3.new(0, 7, 0)
	coreLabel.AlwaysOnTop = true
	coreLabel.Parent = core

	local coreLabelText = Instance.new("TextLabel")
	coreLabelText.Size = UDim2.fromScale(1, 1)
	coreLabelText.BackgroundTransparency = 1
	coreLabelText.TextColor3 = Color3.fromRGB(255, 255, 255)
	coreLabelText.Font = Enum.Font.GothamBold
	coreLabelText.TextSize = 20
	coreLabelText.TextStrokeTransparency = 0.4
	coreLabelText.Text = "Clique pour farmer de l'energie !"
	coreLabelText.Parent = coreLabel

	-- ============================ pet shop stall ============================

	local shop = Instance.new("Part")
	shop.Name = "PetShop"
	shop.Size = Vector3.new(8, 8, 4)
	shop.Anchored = true
	shop.CanCollide = true
	shop.Material = Enum.Material.WoodPlanks
	shop.Color = Color3.fromRGB(200, 170, 110)
	shop.Position = Vector3.new(26, 4, 20)
	shop.Parent = map

	local shopLabel = Instance.new("BillboardGui")
	shopLabel.Name = "ShopLabel"
	shopLabel.Size = UDim2.fromOffset(180, 36)
	shopLabel.StudsOffset = Vector3.new(0, 5.5, 0)
	shopLabel.AlwaysOnTop = true
	shopLabel.Parent = shop

	local shopLabelText = Instance.new("TextLabel")
	shopLabelText.Size = UDim2.fromScale(1, 1)
	shopLabelText.BackgroundTransparency = 1
	shopLabelText.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopLabelText.Font = Enum.Font.GothamBold
	shopLabelText.TextSize = 18
	shopLabelText.TextStrokeTransparency = 0.4
	shopLabelText.Text = "Boutique de Pets"
	shopLabelText.Parent = shopLabel

	local shopPrompt = Instance.new("ProximityPrompt")
	shopPrompt.Name = "ShopPrompt"
	shopPrompt.ActionText = "Ouvrir"
	shopPrompt.ObjectText = "Boutique de Pets"
	shopPrompt.HoldDuration = 0.15
	shopPrompt.MaxActivationDistance = 12
	shopPrompt.Parent = shop
end

buildMap()
