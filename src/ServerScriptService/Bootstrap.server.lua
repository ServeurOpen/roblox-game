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

makeEvent(RemoteNames.STATE_UPDATED)
makeFunction(RemoteNames.GET_RUN_STATE)
makeEvent(RemoteNames.OPEN_TOWER_MENU)
makeEvent(RemoteNames.REQUEST_BUILD)
makeEvent(RemoteNames.START_WAVE_NOW)
makeEvent(RemoteNames.WAVE_EVENT)
