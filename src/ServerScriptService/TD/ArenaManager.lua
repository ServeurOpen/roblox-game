local Workspace = game:GetService("Workspace")

local ArenaManager = {}

ArenaManager.ARENA_COUNT = 4

-- WaitForChild only waits for the "Arenas" folder itself to exist, which
-- happens the instant ArenaSetup.server.lua creates it - well before that
-- script's per-arena loop has actually built any waypoints/tiles. Every
-- caller here needs the fully-built arenas, so also wait for the Ready
-- attribute ArenaSetup sets once it's truly done.
local function getArenasFolder()
	local folder = Workspace:WaitForChild("Arenas")
	if not folder:GetAttribute("Ready") then
		folder:GetAttributeChangedSignal("Ready"):Wait()
	end
	return folder
end

local function getArenaModel(arenaIndex)
	return getArenasFolder():FindFirstChild("Arena" .. arenaIndex)
end
ArenaManager.GetArenaModel = getArenaModel

-- Blocks until every arena (waypoints, tiles, etc.) is fully built. Call
-- this before iterating arenas/tiles directly (not through the other
-- functions here, which already wait internally).
function ArenaManager.WaitUntilReady()
	getArenasFolder()
end

function ArenaManager.GetFreeArenaIndex()
	for i = 1, ArenaManager.ARENA_COUNT do
		local arena = getArenaModel(i)
		if arena and arena:GetAttribute("OwnerUserId") == nil then
			return i
		end
	end
	return nil
end

function ArenaManager.ClaimArena(player, arenaIndex)
	local arena = getArenaModel(arenaIndex)
	if not arena then
		return false
	end

	local currentOwner = arena:GetAttribute("OwnerUserId")
	if currentOwner ~= nil and currentOwner ~= player.UserId then
		return false
	end

	arena:SetAttribute("OwnerUserId", player.UserId)
	return true
end

function ArenaManager.ReleaseArena(arenaIndex)
	local arena = getArenaModel(arenaIndex)
	if arena then
		arena:SetAttribute("OwnerUserId", nil)
	end
end

function ArenaManager.IsArenaFree(arenaIndex)
	local arena = getArenaModel(arenaIndex)
	return arena ~= nil and arena:GetAttribute("OwnerUserId") == nil
end

-- Ordered world-space waypoints (Waypoint1, Waypoint2, ...) for this arena.
function ArenaManager.GetWaypoints(arenaIndex)
	local arena = getArenaModel(arenaIndex)
	if not arena then
		return {}
	end

	local waypointsFolder = arena:FindFirstChild("Waypoints")
	if not waypointsFolder then
		return {}
	end

	local count = #waypointsFolder:GetChildren()
	local points = table.create(count)
	for i = 1, count do
		local marker = waypointsFolder:FindFirstChild("Waypoint" .. i)
		if marker then
			points[i] = marker.Position
		end
	end
	return points
end

function ArenaManager.GetTilesFolder(arenaIndex)
	local arena = getArenaModel(arenaIndex)
	return arena and arena:FindFirstChild("Tiles")
end

-- Centered on the arena's own ground part rather than derived from the
-- waypoints/path, so it always lands safely inside the arena bounds no
-- matter how the path layout changes later.
function ArenaManager.GetSpawnCFrame(arenaIndex)
	local arena = getArenaModel(arenaIndex)
	local ground = arena and arena:FindFirstChild("Ground")
	if not ground then
		return nil
	end
	return CFrame.new(ground.Position + Vector3.new(0, 4, 0))
end

return ArenaManager
