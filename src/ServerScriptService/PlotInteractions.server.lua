local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
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

local function teleportToPlot(player, plotIndex)
	local cframe = PlotManager.GetSpawnCFrame(plotIndex)
	if not cframe then
		return
	end

	local character = player.Character or player.CharacterAdded:Wait()
	character:PivotTo(cframe)
end

local function assignPlot(player, data)
	local plotIndex = data.PlotIndex

	if plotIndex and not PlotManager.ClaimPlot(player, plotIndex) then
		-- Someone else ended up on their saved plot (e.g. after a server
		-- restart race); fall back to finding them a new one.
		plotIndex = nil
	end

	if not plotIndex then
		plotIndex = PlotManager.GetFreePlotIndex()
		if not plotIndex or not PlotManager.ClaimPlot(player, plotIndex) then
			-- All plots are taken; nothing to assign right now.
			return
		end
	end

	data.PlotIndex = plotIndex
	activePlotByUser[player.UserId] = plotIndex

	PlotManager.RenderGenerators(plotIndex, data.GeneratorCount)
	PlotManager.UpdateStats(plotIndex, data.GeneratorCount)
	updateBuyPromptText(plotIndex, data.GeneratorCount)
	teleportToPlot(player, plotIndex)

	player.CharacterAdded:Connect(function()
		teleportToPlot(player, plotIndex)
	end)
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
	PlotManager.UpdateStats(plotIndex, data.GeneratorCount)
	updateBuyPromptText(plotIndex, data.GeneratorCount)
end

local function setupPlot(plotIndex)
	local plot = Workspace.Plots:FindFirstChild("Plot" .. plotIndex)
	if not plot then
		return
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

PlayerData.DataLoaded:Connect(assignPlot)

Players.PlayerRemoving:Connect(function(player)
	local plotIndex = activePlotByUser[player.UserId]
	if plotIndex then
		PlotManager.ReleasePlot(plotIndex)
		activePlotByUser[player.UserId] = nil
	end
end)
