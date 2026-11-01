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

makeEvent(RemoteNames.STATE_UPDATED)
makeEvent(RemoteNames.CLICK_CORE)
makeEvent(RemoteNames.OPEN_PET_SHOP)
makeEvent(RemoteNames.BUY_PET)
makeEvent(RemoteNames.EQUIP_PET)
makeEvent(RemoteNames.UNEQUIP_PET)
