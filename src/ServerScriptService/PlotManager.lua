local Workspace = game:GetService("Workspace")

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

-- Rebuilds the visible generator parts on a plot to match generatorCount.
-- Called on claim and on every purchase so a rejoining player sees their
-- progress even though parts themselves aren't saved, only the count is.
function PlotManager.RenderGenerators(plotIndex, generatorCount)
	local plot = getPlotModel(plotIndex)
	if not plot then
		return
	end

	local generatorsFolder = plot:FindFirstChild("Generators")
	if generatorsFolder then
		generatorsFolder:Destroy()
	end

	generatorsFolder = Instance.new("Folder")
	generatorsFolder.Name = "Generators"
	generatorsFolder.Parent = plot

	local base = plot:FindFirstChild("Base")
	if not base then
		return
	end

	local accent = plot:GetAttribute("AccentColor") or Color3.fromRGB(90, 210, 150)
	local perRow = 5
	local colSpacing = 6
	local rowSpacing = 4

	for i = 1, generatorCount do
		local row = math.floor((i - 1) / perRow)
		local col = (i - 1) % perRow

		local part = Instance.new("Part")
		part.Name = "Generator"
		part.Size = Vector3.new(3, 3, 3)
		part.Anchored = true
		part.Color = accent
		part.Material = Enum.Material.Neon
		part.Position = base.Position
			+ Vector3.new(-12 + col * colSpacing, 2.5, -4 - row * rowSpacing)
		part.Parent = generatorsFolder

		local light = Instance.new("PointLight")
		light.Color = accent
		light.Range = 8
		light.Brightness = 1.5
		light.Parent = part
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
