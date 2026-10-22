local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.RemoteNames)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function makeEvent(name)
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = remotes
end

local function makeFunction(name)
	local f = Instance.new("RemoteFunction")
	f.Name = name
	f.Parent = remotes
end

makeEvent(RemoteNames.CASH_UPDATED)
makeEvent(RemoteNames.PURCHASE_BOOSTER)
makeFunction(RemoteNames.GET_PLAYER_DATA)
