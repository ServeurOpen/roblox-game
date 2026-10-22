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

	local perRow = 5
	local spacing = 6
	for i = 1, generatorCount do
		local row = math.floor((i - 1) / perRow)
		local col = (i - 1) % perRow

		local part = Instance.new("Part")
		part.Name = "Generator"
		part.Size = Vector3.new(4, 4, 4)
		part.Anchored = true
		part.Color = Color3.fromRGB(80, 170, 90)
		part.Material = Enum.Material.Neon
		part.Position = base.Position
			+ Vector3.new(-12 + col * spacing, 3, -12 + row * spacing)
		part.Parent = generatorsFolder
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

	if plot:GetAttribute("OwnerUserId") ~= nil then
		return false
	end

	plot:SetAttribute("OwnerUserId", player.UserId)

	local sign = plot:FindFirstChild("Sign", true)
	if sign and sign:IsA("TextLabel") then
		sign.Text = player.Name .. "'s plot"
	end

	return true
end

function PlotManager.ReleasePlot(plotIndex)
	local plot = getPlotModel(plotIndex)
	if not plot then
		return
	end

	plot:SetAttribute("OwnerUserId", nil)

	local sign = plot:FindFirstChild("Sign", true)
	if sign and sign:IsA("TextLabel") then
		sign.Text = "Free plot - claim me!"
	end
end

function PlotManager.IsPlotFree(plotIndex)
	local plot = getPlotModel(plotIndex)
	return plot ~= nil and plot:GetAttribute("OwnerUserId") == nil
end

return PlotManager
