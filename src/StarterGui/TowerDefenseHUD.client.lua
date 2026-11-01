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
local openTowerMenu = remotes:WaitForChild(RemoteNames.OPEN_TOWER_MENU)
local requestBuild = remotes:WaitForChild(RemoteNames.REQUEST_BUILD)
local startWaveNow = remotes:WaitForChild(RemoteNames.START_WAVE_NOW)
local waveEvent = remotes:WaitForChild(RemoteNames.WAVE_EVENT)

-- Ordered so the tower picker lists them by unlock wave.
local TOWER_ORDER = { "cannon", "archer", "frost", "fire", "tesla" }

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
statLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statLayout.Padding = UDim.new(0, 12)
statLayout.Parent = statBar

local function makeStatLabel(name, defaultText)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(0, 110, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Text = defaultText
	label.Parent = statBar
	return label
end

local goldLabel = makeStatLabel("Gold", "Or: --")
local livesLabel = makeStatLabel("Lives", "Vies: --")
local waveLabel = makeStatLabel("Wave", "Vague: --")

-- ============================ banner ============================

local banner = Instance.new("TextLabel")
banner.Name = "Banner"
banner.Size = UDim2.new(0, 560, 0, 50)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 70)
banner.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
banner.BackgroundTransparency = 0.3
banner.TextColor3 = Color3.fromRGB(255, 220, 120)
banner.Font = Enum.Font.GothamBold
banner.TextSize = 18
banner.TextWrapped = true
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
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 3),
		{ BackgroundTransparency = 1, TextTransparency = 1 }
	)
	tween:Play()
end

waveEvent.OnClientEvent:Connect(showBanner)

-- ============================ start-wave button ============================

local startWaveButton = Instance.new("TextButton")
startWaveButton.Name = "StartWaveButton"
startWaveButton.Size = UDim2.new(0, 220, 0, 40)
startWaveButton.AnchorPoint = Vector2.new(0.5, 1)
startWaveButton.Position = UDim2.new(0.5, 0, 1, -16)
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

-- ============================ tower picker popup ============================
-- Opens right on screen when the player interacts with an empty build
-- tile (server-triggered via OPEN_TOWER_MENU), instead of requiring a
-- tower to be pre-selected from a permanent menu - walk up, press E,
-- pick a tower, done.

-- A TextButton (not a Frame) so clicking the backdrop to close works:
-- MouseButton1Click only exists on GuiButton subclasses.
local pickerOverlay = Instance.new("TextButton")
pickerOverlay.Name = "TowerPickerOverlay"
pickerOverlay.Size = UDim2.fromScale(1, 1)
pickerOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
pickerOverlay.BackgroundTransparency = 0.55
pickerOverlay.AutoButtonColor = false
pickerOverlay.Text = ""
pickerOverlay.Visible = false
pickerOverlay.ZIndex = 10
pickerOverlay.Parent = screenGui

local pickerPanel = Instance.new("Frame")
pickerPanel.Name = "TowerPickerPanel"
-- Tall enough for 2 columns x 3 rows now that Tesla makes 5 towers.
pickerPanel.Size = UDim2.new(0, 300, 0, 360)
pickerPanel.AnchorPoint = Vector2.new(0.5, 0.5)
pickerPanel.Position = UDim2.fromScale(0.5, 0.5)
pickerPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
pickerPanel.ZIndex = 11
pickerPanel.Parent = pickerOverlay

local pickerPanelCorner = Instance.new("UICorner")
pickerPanelCorner.CornerRadius = UDim.new(0, 12)
pickerPanelCorner.Parent = pickerPanel

local pickerTitle = Instance.new("TextLabel")
pickerTitle.Size = UDim2.new(1, 0, 0, 36)
pickerTitle.BackgroundTransparency = 1
pickerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
pickerTitle.Font = Enum.Font.GothamBold
pickerTitle.TextSize = 18
pickerTitle.Text = "Choisis une tour"
pickerTitle.ZIndex = 11
pickerTitle.Parent = pickerPanel

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Position = UDim2.new(1, -34, 0, 4)
closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.Text = "X"
closeButton.ZIndex = 12
closeButton.Parent = pickerPanel

local closeButtonCorner = Instance.new("UICorner")
closeButtonCorner.CornerRadius = UDim.new(0, 6)
closeButtonCorner.Parent = closeButton

local pickerGrid = Instance.new("Frame")
pickerGrid.Size = UDim2.new(1, -20, 1, -50)
pickerGrid.Position = UDim2.new(0, 10, 0, 42)
pickerGrid.BackgroundTransparency = 1
pickerGrid.ZIndex = 11
pickerGrid.Parent = pickerPanel

local pickerLayout = Instance.new("UIGridLayout")
pickerLayout.CellSize = UDim2.new(0, 128, 0, 100)
pickerLayout.CellPadding = UDim2.new(0, 8, 0, 8)
pickerLayout.Parent = pickerGrid

local activeTile = nil

local function closePicker()
	pickerOverlay.Visible = false
	activeTile = nil
end

closeButton.MouseButton1Click:Connect(closePicker)
pickerOverlay.MouseButton1Click:Connect(closePicker)

local currentWave = 0

local pickerButtons = {}

for _, key in ipairs(TOWER_ORDER) do
	local def = TowerTypes[key]

	local button = Instance.new("TextButton")
	button.Name = key
	button.BackgroundColor3 = def.color
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = Color3.fromRGB(20, 20, 20)
	button.TextWrapped = true
	button.Text = def.name .. "\n" .. def.baseCost .. " or"
	button.ZIndex = 12
	button.Parent = pickerGrid

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	button.MouseButton1Click:Connect(function()
		if not activeTile then
			return
		end
		if def.unlockWave > math.max(currentWave, 1) then
			return
		end
		requestBuild:FireServer(activeTile, key)
		closePicker()
	end)

	pickerButtons[key] = { button = button, def = def }
end

local function refreshPickerLocks()
	for key, entry in pairs(pickerButtons) do
		local unlocked = entry.def.unlockWave <= math.max(currentWave, 1)
		entry.button.BackgroundTransparency = unlocked and 0 or 0.6
		entry.button.AutoButtonColor = unlocked
	end
end

openTowerMenu.OnClientEvent:Connect(function(tile)
	activeTile = tile
	refreshPickerLocks()
	pickerOverlay.Visible = true
end)

-- ============================ state handling ============================

local waveDeadline = 0 -- client-local tick() deadline for the next wave countdown
local currentStatus = "waiting"

local function applyState(data)
	currentWave = data.Wave
	currentStatus = data.Status

	goldLabel.Text = "Or: " .. math.floor(data.Gold)
	livesLabel.Text = "Vies: " .. data.Lives
	waveLabel.Text = "Vague: " .. data.Wave

	waveDeadline = tick() + (data.WaveCountdown or 0)
	startWaveButton.Visible = (data.Status == "waiting")

	refreshPickerLocks()
end

stateUpdated.OnClientEvent:Connect(applyState)

-- The server creates this player's run state asynchronously (after a
-- DataStore read), so the very first InvokeServer can easily land before
-- it exists yet. Retry instead of accepting a single nil.
task.spawn(function()
	for _ = 1, 20 do
		local initial = getRunState:InvokeServer()
		if initial then
			applyState(initial)
			return
		end
		task.wait(0.5)
	end
end)

RunService.RenderStepped:Connect(function()
	if currentStatus == "waiting" then
		local remaining = math.max(0, waveDeadline - tick())
		startWaveButton.Text = string.format("Start Wave (%.0fs)", remaining)
	end
end)
