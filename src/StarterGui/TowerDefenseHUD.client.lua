local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local RemoteNames = require(ReplicatedStorage.RemoteNames)
local TowerTypes = require(ReplicatedStorage.TD.TowerTypes)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateUpdated = remotes:WaitForChild(RemoteNames.STATE_UPDATED)
local getRunState = remotes:WaitForChild(RemoteNames.GET_RUN_STATE)
local selectTowerType = remotes:WaitForChild(RemoteNames.SELECT_TOWER_TYPE)
local startWaveNow = remotes:WaitForChild(RemoteNames.START_WAVE_NOW)
local waveEvent = remotes:WaitForChild(RemoteNames.WAVE_EVENT)

-- Ordered so the build menu lists towers by unlock wave.
local TOWER_ORDER = { "cannon", "archer", "frost", "fire" }

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TowerDefenseHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- ============================ top stat bar ============================

local statBar = Instance.new("Frame")
statBar.Name = "StatBar"
statBar.Size = UDim2.new(0, 360, 0, 44)
statBar.Position = UDim2.new(0, 10, 0, 10)
statBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
statBar.BackgroundTransparency = 0.25
statBar.Parent = screenGui

local statBarCorner = Instance.new("UICorner")
statBarCorner.CornerRadius = UDim.new(0, 8)
statBarCorner.Parent = statBar

local statLayout = Instance.new("UIListLayout")
statLayout.FillDirection = Enum.FillDirection.Horizontal
statLayout.VerticalAlignment = Enum.VerticalAlignment.Center
statLayout.HorizontalAlignment = Enum.HorizontalAlignment.SpaceEvenly
statLayout.Parent = statBar

local function makeStatLabel(name)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(0, 110, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Parent = statBar
	return label
end

local goldLabel = makeStatLabel("Gold")
local livesLabel = makeStatLabel("Lives")
local waveLabel = makeStatLabel("Wave")

-- ============================ banner ============================

local banner = Instance.new("TextLabel")
banner.Name = "Banner"
banner.Size = UDim2.new(0, 500, 0, 50)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 70)
banner.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
banner.BackgroundTransparency = 0.3
banner.TextColor3 = Color3.fromRGB(255, 220, 120)
banner.Font = Enum.Font.GothamBold
banner.TextSize = 22
banner.Text = ""
banner.Visible = false
banner.Parent = screenGui

local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 8)
bannerCorner.Parent = banner

local function showBanner(text)
	banner.Text = text
	banner.Visible = true
	banner.BackgroundTransparency = 0.3
	banner.TextTransparency = 0

	local tween = TweenService:Create(
		banner,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.5),
		{ BackgroundTransparency = 1, TextTransparency = 1 }
	)
	tween:Play()
end

waveEvent.OnClientEvent:Connect(showBanner)

-- ============================ build menu ============================

local buildMenu = Instance.new("Frame")
buildMenu.Name = "BuildMenu"
buildMenu.Size = UDim2.new(0, 560, 0, 70)
buildMenu.AnchorPoint = Vector2.new(0.5, 1)
buildMenu.Position = UDim2.new(0.5, 0, 1, -16)
buildMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
buildMenu.BackgroundTransparency = 0.25
buildMenu.Parent = screenGui

local buildMenuCorner = Instance.new("UICorner")
buildMenuCorner.CornerRadius = UDim.new(0, 10)
buildMenuCorner.Parent = buildMenu

local buildLayout = Instance.new("UIListLayout")
buildLayout.FillDirection = Enum.FillDirection.Horizontal
buildLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buildLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buildLayout.Padding = UDim.new(0, 10)
buildLayout.Parent = buildMenu

local towerButtons = {}

for _, key in ipairs(TOWER_ORDER) do
	local def = TowerTypes[key]

	local button = Instance.new("TextButton")
	button.Name = key
	button.Size = UDim2.new(0, 120, 0, 54)
	button.BackgroundColor3 = def.color
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = Color3.fromRGB(20, 20, 20)
	button.TextWrapped = true
	button.Text = def.name .. "\n" .. def.baseCost .. " or"
	button.Parent = buildMenu

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 1
	stroke.Parent = button

	button.MouseButton1Click:Connect(function()
		selectTowerType:FireServer(key)
	end)

	towerButtons[key] = { button = button, stroke = stroke, def = def }
end

-- ============================ start-wave button ============================

local startWaveButton = Instance.new("TextButton")
startWaveButton.Name = "StartWaveButton"
startWaveButton.Size = UDim2.new(0, 220, 0, 40)
startWaveButton.AnchorPoint = Vector2.new(0.5, 1)
startWaveButton.Position = UDim2.new(0.5, 0, 1, -96)
startWaveButton.BackgroundColor3 = Color3.fromRGB(90, 200, 120)
startWaveButton.Font = Enum.Font.GothamBold
startWaveButton.TextSize = 16
startWaveButton.TextColor3 = Color3.fromRGB(15, 15, 15)
startWaveButton.Text = "Start Wave"
startWaveButton.Visible = false
startWaveButton.Parent = screenGui

local startWaveCorner = Instance.new("UICorner")
startWaveCorner.CornerRadius = UDim.new(0, 8)
startWaveCorner.Parent = startWaveButton

startWaveButton.MouseButton1Click:Connect(function()
	startWaveNow:FireServer()
end)

-- ============================ state handling ============================

local currentState = {
	Gold = 0,
	Lives = 0,
	Wave = 0,
	Status = "idle",
	SelectedTowerKey = nil,
}
local waveDeadline = 0 -- client-local tick() deadline for the next wave countdown

local function refreshBuildMenu()
	for key, entry in pairs(towerButtons) do
		local unlocked = entry.def.unlockWave <= math.max(currentState.Wave, 1)
		entry.button.BackgroundTransparency = unlocked and 0 or 0.6
		entry.button.AutoButtonColor = unlocked
		entry.stroke.Transparency = (currentState.SelectedTowerKey == key) and 0 or 1
	end
end

local function applyState(data)
	currentState.Gold = data.Gold
	currentState.Lives = data.Lives
	currentState.Wave = data.Wave
	currentState.Status = data.Status
	currentState.SelectedTowerKey = data.SelectedTowerKey

	goldLabel.Text = "Or: " .. math.floor(data.Gold)
	livesLabel.Text = "Vies: " .. data.Lives
	waveLabel.Text = "Vague: " .. data.Wave

	waveDeadline = tick() + (data.WaveCountdown or 0)
	startWaveButton.Visible = (data.Status == "waiting")

	refreshBuildMenu()
end

stateUpdated.OnClientEvent:Connect(applyState)

local initial = getRunState:InvokeServer()
if initial then
	applyState(initial)
end

RunService.RenderStepped:Connect(function()
	if currentState.Status == "waiting" then
		local remaining = math.max(0, waveDeadline - tick())
		startWaveButton.Text = string.format("Start Wave (%.0fs)", remaining)
	end
end)
