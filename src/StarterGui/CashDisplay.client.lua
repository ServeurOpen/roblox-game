local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local RemoteNames = require(ReplicatedStorage.RemoteNames)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local cashUpdated = remotes:WaitForChild(RemoteNames.CASH_UPDATED)
local getPlayerData = remotes:WaitForChild(RemoteNames.GET_PLAYER_DATA)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CashGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local container = Instance.new("Frame")
container.Name = "CashContainer"
container.Size = UDim2.new(0, 220, 0, 40)
container.Position = UDim2.new(0, 10, 0, 10)
container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
container.BackgroundTransparency = 0.3
container.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = container

local label = Instance.new("TextLabel")
label.Name = "CashLabel"
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextSize = 20
label.Text = "Cash: 0"
label.Parent = container

local currentCash = 0

local function punchLabel()
	local punchUp = TweenService:Create(
		container,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 236, 0, 44) }
	)
	punchUp:Play()
	punchUp.Completed:Connect(function()
		TweenService:Create(
			container,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Size = UDim2.new(0, 220, 0, 40) }
		):Play()
	end)
end

local function showGainPopup(amount)
	local popup = Instance.new("TextLabel")
	popup.Size = UDim2.new(0, 120, 0, 24)
	popup.Position = UDim2.new(0, 230, 0, 8)
	popup.BackgroundTransparency = 1
	popup.TextColor3 = Color3.fromRGB(120, 255, 140)
	popup.TextStrokeTransparency = 0.5
	popup.Font = Enum.Font.GothamBold
	popup.TextSize = 18
	popup.Text = "+" .. amount
	popup.Parent = container

	local tween = TweenService:Create(
		popup,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = popup.Position + UDim2.new(0, 0, 0, -20), TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	tween:Play()
	Debris:AddItem(popup, 0.85)
end

local function setCash(amount)
	local delta = amount - currentCash
	currentCash = amount
	label.Text = "Cash: " .. tostring(amount)

	if delta > 0 then
		punchLabel()
		showGainPopup(delta)
	end
end

cashUpdated.OnClientEvent:Connect(setCash)

local initial = getPlayerData:InvokeServer()
currentCash = initial
label.Text = "Cash: " .. tostring(initial)
