local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)

local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "Plots"
plotsFolder.Parent = Workspace

for i = 1, GameConfig.PlotCount do
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. i
	plot:SetAttribute("PlotIndex", i)
	plot.Parent = plotsFolder

	local centerX = (i - 1) * GameConfig.PlotSpacing

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(40, 1, 40)
	base.Anchored = true
	base.Color = Color3.fromRGB(60, 120, 60)
	base.Position = Vector3.new(centerX, 0, 0)
	base.Parent = plot

	local signPart = Instance.new("Part")
	signPart.Name = "SignPart"
	signPart.Size = Vector3.new(6, 4, 0.5)
	signPart.Anchored = true
	signPart.Color = Color3.fromRGB(30, 30, 30)
	signPart.Position = Vector3.new(centerX, 2.5, -19)
	signPart.Parent = plot

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = signPart

	local sign = Instance.new("TextLabel")
	sign.Name = "Sign"
	sign.Size = UDim2.fromScale(1, 1)
	sign.BackgroundTransparency = 1
	sign.TextColor3 = Color3.fromRGB(255, 255, 255)
	sign.TextScaled = true
	sign.Font = Enum.Font.GothamBold
	sign.Text = "Free plot - claim me!"
	sign.Parent = surfaceGui

	local claimPad = Instance.new("Part")
	claimPad.Name = "ClaimPad"
	claimPad.Size = Vector3.new(6, 1, 6)
	claimPad.Anchored = true
	claimPad.Color = Color3.fromRGB(80, 140, 220)
	claimPad.Position = Vector3.new(centerX, 1, -14)
	claimPad.Parent = plot

	local claimPrompt = Instance.new("ProximityPrompt")
	claimPrompt.Name = "ClaimPrompt"
	claimPrompt.ActionText = "Claim plot"
	claimPrompt.ObjectText = "Plot " .. i
	claimPrompt.HoldDuration = 0.5
	claimPrompt.MaxActivationDistance = 10
	claimPrompt.Parent = claimPad

	local buyPad = Instance.new("Part")
	buyPad.Name = "BuyGeneratorPad"
	buyPad.Size = Vector3.new(6, 1, 6)
	buyPad.Anchored = true
	buyPad.Color = Color3.fromRGB(220, 170, 60)
	buyPad.Position = Vector3.new(centerX, 1, 14)
	buyPad.Parent = plot

	local buyPrompt = Instance.new("ProximityPrompt")
	buyPrompt.Name = "BuyGeneratorPrompt"
	buyPrompt.ActionText = "Buy generator"
	buyPrompt.ObjectText = "Cost: " .. GameConfig.GeneratorBaseCost
	buyPrompt.HoldDuration = 0.2
	buyPrompt.MaxActivationDistance = 10
	buyPrompt.Parent = buyPad
end
