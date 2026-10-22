local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.GameConfig)
local RemoteNames = require(ReplicatedStorage.RemoteNames)
local PlayerData = require(ServerScriptService.PlayerData)
local PlotManager = require(ServerScriptService.PlotManager)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local cashUpdated = remotes:WaitForChild(RemoteNames.CASH_UPDATED)

-- Tracked independently of PlayerData's cache, which another listener may
-- have already cleared by the time PlayerRemoving reaches this script
-- (listener order across scripts isn't guaranteed).
local activePlotByUser = {}

local function generatorCost(generatorCount)
	return math.floor(GameConfig.GeneratorBaseCost * (GameConfig.GeneratorCostMultiplier ^ generatorCount))
end

local function updateBuyPromptText(plotIndex, generatorCount)
	local plot = Workspace.Plots:FindFirstChild("Plot" .. plotIndex)
	if not plot then
		return
	end

	local prompt = plot:FindFirstChild("BuyGeneratorPrompt", true)
	if prompt then
		if generatorCount >= GameConfig.MaxGeneratorsPerPlot then
			prompt.ObjectText = "Plot full"
		else
			prompt.ObjectText = "Cost: " .. generatorCost(generatorCount)
		end
	end
end

local function onClaimTriggered(player, plotIndex)
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	if data.PlotIndex ~= nil then
		-- Already owns a plot; ignore extra claim attempts.
		return
	end

	if PlotManager.ClaimPlot(player, plotIndex) then
		data.PlotIndex = plotIndex
		activePlotByUser[player.UserId] = plotIndex
		PlotManager.RenderGenerators(plotIndex, data.GeneratorCount)
		updateBuyPromptText(plotIndex, data.GeneratorCount)
	end
end

local function onBuyTriggered(player, plotIndex)
	local data = PlayerData.Get(player)
	if not data or data.PlotIndex ~= plotIndex then
		-- Only the plot's owner can buy generators on it.
		return
	end

	if data.GeneratorCount >= GameConfig.MaxGeneratorsPerPlot then
		return
	end

	local cost = generatorCost(data.GeneratorCount)
	if data.Cash < cost then
		return
	end

	data.Cash -= cost
	data.GeneratorCount += 1

	cashUpdated:FireClient(player, data.Cash)
	PlotManager.RenderGenerators(plotIndex, data.GeneratorCount)
	updateBuyPromptText(plotIndex, data.GeneratorCount)
end

local function setupPlot(plotIndex)
	local plot = Workspace.Plots:FindFirstChild("Plot" .. plotIndex)
	if not plot then
		return
	end

	local claimPrompt = plot:FindFirstChild("ClaimPrompt", true)
	if claimPrompt then
		claimPrompt.Triggered:Connect(function(player)
			onClaimTriggered(player, plotIndex)
		end)
	end

	local buyPrompt = plot:FindFirstChild("BuyGeneratorPrompt", true)
	if buyPrompt then
		buyPrompt.Triggered:Connect(function(player)
			onBuyTriggered(player, plotIndex)
		end)
	end
end

Workspace:WaitForChild("Plots")
for i = 1, GameConfig.PlotCount do
	setupPlot(i)
end

-- Re-attach a returning player to their saved plot if it's still free, and
-- rebuild their generators so progress is visible again. Otherwise they
-- keep their generator count/cash but must claim a (possibly different)
-- free plot manually.
PlayerData.DataLoaded:Connect(function(player, data)
	if data.PlotIndex and PlotManager.IsPlotFree(data.PlotIndex) then
		if PlotManager.ClaimPlot(player, data.PlotIndex) then
			activePlotByUser[player.UserId] = data.PlotIndex
			PlotManager.RenderGenerators(data.PlotIndex, data.GeneratorCount)
			updateBuyPromptText(data.PlotIndex, data.GeneratorCount)
		end
	elseif data.PlotIndex then
		-- Someone else is on their saved plot (unlikely but possible after
		-- a server restart race); they'll need to claim a new one.
		data.PlotIndex = nil
	end
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	local plotIndex = activePlotByUser[player.UserId]
	if plotIndex then
		PlotManager.ReleasePlot(plotIndex)
		activePlotByUser[player.UserId] = nil
	end
end)
