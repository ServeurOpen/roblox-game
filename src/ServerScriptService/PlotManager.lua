local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(game:GetService("ReplicatedStorage").GameConfig)

local PlotManager = {}

-- Fetched lazily (not cached at require-time) because PlotSetup.server.lua,
-- which creates this folder, may not have run yet when this module loads.
local function getPlotsFolder()
	return Workspace:WaitForChild("Plots")
end

local function getPlotModel(plotIndex)
	return getPlotsFolder():FindFirstChild("Plot" .. plotIndex)
end

local GENERATOR_SIZE = Vector3.new(3, 3, 3)
local PER_ROW = 5
local COL_SPACING = 6
local ROW_SPACING = 4

local function generatorOffset(index)
	local row = math.floor((index - 1) / PER_ROW)
	local col = (index - 1) % PER_ROW
	return Vector3.new(-12 + col * COL_SPACING, 2.5, -4 - row * ROW_SPACING)
end

local function playPurchaseEffect(part, accent)
	part.Size = Vector3.new(0.2, 0.2, 0.2)

	local growTween = TweenService:Create(
		part,
		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = GENERATOR_SIZE }
	)
	growTween:Play()

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Lifetime = NumberRange.new(0.4, 0.8)
	sparkles.Rate = 0
	sparkles.Speed = NumberRange.new(4, 8)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Color = ColorSequence.new(accent)
	sparkles.Parent = part
	sparkles:Emit(24)
	Debris:AddItem(sparkles, 1.5)

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.6
	sound.Parent = part
	sound:Play()
	Debris:AddItem(sound, 2)
end

-- Syncs the visible generator parts on a plot up to targetCount, only
-- adding the parts that are missing (doesn't touch ones already there).
-- Called on claim/rejoin (animateNew = false, instant) and on purchase
-- (animateNew = true, pops in with a tween + sparkles + sound).
function PlotManager.SyncGenerators(plotIndex, targetCount, animateNew)
	local plot = getPlotModel(plotIndex)
	if not plot then
		return
	end

	local base = plot:FindFirstChild("Base")
	if not base then
		return
	end

	local generatorsFolder = plot:FindFirstChild("Generators")
	if not generatorsFolder then
		generatorsFolder = Instance.new("Folder")
		generatorsFolder.Name = "Generators"
		generatorsFolder.Parent = plot
	end

	local existingCount = #generatorsFolder:GetChildren()
	if existingCount > targetCount then
		generatorsFolder:ClearAllChildren()
		existingCount = 0
	end

	local accent = plot:GetAttribute("AccentColor") or Color3.fromRGB(90, 210, 150)

	for i = existingCount + 1, targetCount do
		local part = Instance.new("Part")
		part.Name = "Generator"
		part.Size = GENERATOR_SIZE
		part.Anchored = true
		part.Color = accent
		part.Material = Enum.Material.Neon
		part.Position = base.Position + generatorOffset(i)
		part.Parent = generatorsFolder

		local light = Instance.new("PointLight")
		light.Color = accent
		light.Range = 8
		light.Brightness = 1.5
		light.Parent = part

		if animateNew then
			playPurchaseEffect(part, accent)
		end
	end
end

function PlotManager.UpdateStats(plotIndex, generatorCount)
	local plot = getPlotModel(plotIndex)
	if not plot then
		return
	end

	local statsLabel = plot:FindFirstChild("StatsLabel", true)
	if statsLabel and statsLabel:IsA("TextLabel") then
		statsLabel.Text = "Generators: " .. generatorCount
	end
end

function PlotManager.GetFreePlotIndex()
	for i = 1, GameConfig.PlotCount do
		local plot = getPlotModel(i)
		if plot and plot:GetAttribute("OwnerUserId") == nil then
			return i
		end
	end

	return nil
end

function PlotManager.ClaimPlot(player, plotIndex)
	local plot = getPlotModel(plotIndex)
	if not plot then
		return false
	end

	local currentOwner = plot:GetAttribute("OwnerUserId")
	if currentOwner ~= nil and currentOwner ~= player.UserId then
		return false
	end

	plot:SetAttribute("OwnerUserId", player.UserId)

	local ownerLabel = plot:FindFirstChild("OwnerLabel", true)
	if ownerLabel and ownerLabel:IsA("TextLabel") then
		ownerLabel.Text = player.Name .. "'s factory"
	end

	return true
end

function PlotManager.ReleasePlot(plotIndex)
	local plot = getPlotModel(plotIndex)
	if not plot then
		return
	end

	plot:SetAttribute("OwnerUserId", nil)

	local ownerLabel = plot:FindFirstChild("OwnerLabel", true)
	if ownerLabel and ownerLabel:IsA("TextLabel") then
		ownerLabel.Text = "Empty plot"
	end

	local statsLabel = plot:FindFirstChild("StatsLabel", true)
	if statsLabel and statsLabel:IsA("TextLabel") then
		statsLabel.Text = ""
	end
end

function PlotManager.IsPlotFree(plotIndex)
	local plot = getPlotModel(plotIndex)
	return plot ~= nil and plot:GetAttribute("OwnerUserId") == nil
end

function PlotManager.GetSpawnCFrame(plotIndex)
	local plot = getPlotModel(plotIndex)
	if not plot then
		return nil
	end

	local anchor = plot:FindFirstChild("SpawnAnchor")
	if not anchor then
		return nil
	end

	return anchor.CFrame + Vector3.new(0, 3, 0)
end

return PlotManager
