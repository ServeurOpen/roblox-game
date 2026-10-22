local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.RemoteNames)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local cashUpdated = remotes:WaitForChild(RemoteNames.CASH_UPDATED)
local getPlayerData = remotes:WaitForChild(RemoteNames.GET_PLAYER_DATA)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CashGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "CashLabel"
label.Size = UDim2.new(0, 220, 0, 40)
label.Position = UDim2.new(0, 10, 0, 10)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextSize = 20
label.Text = "Cash: 0"
label.Parent = screenGui

local function setCash(amount)
	label.Text = "Cash: " .. tostring(amount)
end

cashUpdated.OnClientEvent:Connect(setCash)

local initial = getPlayerData:InvokeServer()
setCash(initial)
