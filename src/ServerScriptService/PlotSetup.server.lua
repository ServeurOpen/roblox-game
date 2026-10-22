local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)

-- One accent color per plot, cycled if there are more plots than colors.
local PLOT_COLORS = {
	Color3.fromRGB(235, 100, 90),
	Color3.fromRGB(90, 160, 235),
	Color3.fromRGB(240, 185, 70),
	Color3.fromRGB(140, 110, 230),
	Color3.fromRGB(90, 210, 150),
	Color3.fromRGB(235, 130, 190),
}

-- Guard against a duplicate "Plots" folder if this script somehow runs
-- twice in the same server (e.g. a Rojo sync landing mid-session instead
-- of before a fresh Play), which would otherwise leave two overlapping
-- sets of plots and very confusing "my plot looks empty" bugs.
local existingPlots = Workspace:FindFirstChild("Plots")
if existingPlots then
	existingPlots:Destroy()
end

local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "Plots"
plotsFolder.Parent = Workspace

for i = 1, GameConfig.PlotCount do
	local accent = PLOT_COLORS[((i - 1) % #PLOT_COLORS) + 1]

	local plot = Instance.new("Model")
	plot.Name = "Plot" .. i
	plot:SetAttribute("PlotIndex", i)
	plot:SetAttribute("AccentColor", accent)
	plot.Parent = plotsFolder

	local centerX = (i - 1) * GameConfig.PlotSpacing

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(40, 1, 40)
	base.Anchored = true
	base.Material = Enum.Material.Grass
	base.Color = Color3.fromRGB(70, 150, 80)
	base.Position = Vector3.new(centerX, 0, 0)
	base.Parent = plot

	-- Thin accent trim along the front edge so each plot reads as its own
	-- color from a distance, without blocking movement.
	local trim = Instance.new("Part")
	trim.Name = "Trim"
	trim.Size = Vector3.new(40, 0.2, 2)
	trim.Anchored = true
	trim.CanCollide = false
	trim.Material = Enum.Material.Neon
	trim.Color = accent
	trim.Position = Vector3.new(centerX, 1.1, 19)
	trim.Parent = plot

	-- Decorative corner pillars.
	for _, corner in ipairs({ { -19, -19 }, { 19, -19 }, { -19, 19 }, { 19, 19 } }) do
		local pillar = Instance.new("Part")
		pillar.Name = "Pillar"
		pillar.Size = Vector3.new(2, 6, 2)
		pillar.Anchored = true
		pillar.Material = Enum.Material.Wood
		pillar.Color = Color3.fromRGB(90, 60, 40)
		pillar.Position = Vector3.new(centerX + corner[1], 3, corner[2])
		pillar.Parent = plot
	end

	-- Invisible reference point used to teleport the owner onto their plot.
	local spawnAnchor = Instance.new("Part")
	spawnAnchor.Name = "SpawnAnchor"
	spawnAnchor.Size = Vector3.new(4, 1, 4)
	spawnAnchor.Anchored = true
	spawnAnchor.CanCollide = false
	spawnAnchor.Transparency = 1
	spawnAnchor.Position = Vector3.new(centerX, 2, 15)
	spawnAnchor.Parent = plot

	-- Floating nameplate above the plot.
	local postPart = Instance.new("Part")
	postPart.Name = "NamePost"
	postPart.Size = Vector3.new(1, 8, 1)
	postPart.Anchored = true
	postPart.Material = Enum.Material.Metal
	postPart.Color = Color3.fromRGB(40, 40, 40)
	postPart.Position = Vector3.new(centerX, 4, -18)
	postPart.Parent = plot

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameBillboard"
	billboard.Size = UDim2.fromOffset(220, 70)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 35
	billboard.Parent = postPart

	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.Name = "OwnerLabel"
	ownerLabel.Size = UDim2.new(1, 0, 0.6, 0)
	ownerLabel.BackgroundTransparency = 1
	ownerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ownerLabel.TextStrokeTransparency = 0.3
	ownerLabel.TextScaled = true
	ownerLabel.Font = Enum.Font.GothamBold
	ownerLabel.Text = "Empty plot"
	ownerLabel.Parent = billboard

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, 0, 0.4, 0)
	statsLabel.Position = UDim2.new(0, 0, 0.6, 0)
	statsLabel.BackgroundTransparency = 1
	statsLabel.TextColor3 = accent
	statsLabel.TextStrokeTransparency = 0.3
	statsLabel.TextScaled = true
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.Text = ""
	statsLabel.Parent = billboard

	local buyPad = Instance.new("Part")
	buyPad.Name = "BuyGeneratorPad"
	buyPad.Size = Vector3.new(6, 1, 6)
	buyPad.Anchored = true
	buyPad.Material = Enum.Material.Neon
	buyPad.Color = accent
	buyPad.Position = Vector3.new(centerX, 1, 0)
	buyPad.Parent = plot

	local buyPrompt = Instance.new("ProximityPrompt")
	buyPrompt.Name = "BuyGeneratorPrompt"
	buyPrompt.ActionText = "Buy generator"
	buyPrompt.ObjectText = "Cost: " .. GameConfig.GeneratorBaseCost
	buyPrompt.HoldDuration = 0.2
	buyPrompt.MaxActivationDistance = 10
	buyPrompt.Parent = buyPad
end
