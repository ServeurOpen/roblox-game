local Workspace = game:GetService("Workspace")

local ARENA_COUNT = 4
local ARENA_SPACING = 90

-- Local (arena-relative) waypoints forming a zigzag road. Enemies walk
-- these in order from Waypoint1 (portal) to the last one (base).
local WAYPOINTS_LOCAL = {
	Vector3.new(-26, 1, -26),
	Vector3.new(26, 1, -26),
	Vector3.new(26, 1, -6),
	Vector3.new(-26, 1, -6),
	Vector3.new(-26, 1, 14),
	Vector3.new(26, 1, 14),
	Vector3.new(26, 1, 26),
}

local ROAD_WIDTH = 6
local TILE_GRID_STEP = 8
local TILE_GRID_RANGE = 30
local TILE_CLEARANCE_FROM_ROAD = 7

-- Guard against a duplicate Arenas folder if this script somehow runs
-- twice in an already-live server (see the same issue + fix in the
-- earlier tycoon build).
local existingArenas = Workspace:FindFirstChild("Arenas")
if existingArenas then
	existingArenas:Destroy()
end

local arenasFolder = Instance.new("Folder")
arenasFolder.Name = "Arenas"
arenasFolder.Parent = Workspace

-- Perpendicular (2D, XZ-plane) distance from point p to segment a-b.
local function distanceToSegment(p, a, b)
	local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local ap = Vector3.new(p.X - a.X, 0, p.Z - a.Z)
	local abLenSq = ab:Dot(ab)
	local t = abLenSq > 0 and math.clamp(ap:Dot(ab) / abLenSq, 0, 1) or 0
	local closest = Vector3.new(a.X + ab.X * t, 0, a.Z + ab.Z * t)
	local d = Vector3.new(p.X - closest.X, 0, p.Z - closest.Z)
	return d.Magnitude
end

local function distanceToPath(p, waypoints)
	local best = math.huge
	for i = 1, #waypoints - 1 do
		best = math.min(best, distanceToSegment(p, waypoints[i], waypoints[i + 1]))
	end
	return best
end

for arenaIndex = 1, ARENA_COUNT do
	local centerX = (arenaIndex - 1) * ARENA_SPACING

	local arena = Instance.new("Model")
	arena.Name = "Arena" .. arenaIndex
	arena:SetAttribute("ArenaIndex", arenaIndex)
	arena.Parent = arenasFolder

	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = Vector3.new(70, 1, 70)
	ground.Anchored = true
	ground.Material = Enum.Material.Grass
	ground.Color = Color3.fromRGB(60, 110, 70)
	ground.Position = Vector3.new(centerX, 0, 0)
	ground.Parent = arena

	-- World-space waypoints for this arena, and a Waypoints folder with one
	-- part per point (used by the enemy spawner/mover and for the client to
	-- visualize nothing extra is needed from them - purely a server lookup).
	local worldWaypoints = {}
	local waypointsFolder = Instance.new("Folder")
	waypointsFolder.Name = "Waypoints"
	waypointsFolder.Parent = arena

	for i, localPoint in ipairs(WAYPOINTS_LOCAL) do
		local worldPoint = Vector3.new(centerX + localPoint.X, localPoint.Y, localPoint.Z)
		worldWaypoints[i] = worldPoint

		local marker = Instance.new("Part")
		marker.Name = "Waypoint" .. i
		marker.Size = Vector3.new(1, 1, 1)
		marker.Anchored = true
		marker.CanCollide = false
		marker.Transparency = 1
		marker.Position = worldPoint
		marker.Parent = waypointsFolder
	end

	-- Road visuals between consecutive waypoints.
	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "Road"
	roadFolder.Parent = arena

	for i = 1, #worldWaypoints - 1 do
		local a, b = worldWaypoints[i], worldWaypoints[i + 1]
		local segment = Instance.new("Part")
		segment.Name = "Segment" .. i
		segment.Anchored = true
		segment.CanCollide = false
		segment.Material = Enum.Material.Slate
		segment.Color = Color3.fromRGB(70, 65, 60)
		local length = (b - a).Magnitude
		segment.Size = Vector3.new(ROAD_WIDTH, 0.4, length)
		segment.CFrame = CFrame.lookAt((a + b) / 2, b)
		segment.Parent = roadFolder
	end

	-- Purely a logical marker (no visual): the previous bright neon disc on
	-- the ground was flagged as ugly, so spawning just happens invisibly at
	-- this point now.
	local portal = Instance.new("Part")
	portal.Name = "Portal"
	portal.Shape = Enum.PartType.Cylinder
	portal.Size = Vector3.new(1, 10, 10)
	portal.Anchored = true
	portal.CanCollide = false
	portal.Transparency = 1
	portal.CFrame = CFrame.new(worldWaypoints[1]) * CFrame.Angles(0, 0, math.rad(90))
	portal.Parent = arena

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(10, 6, 10)
	base.Anchored = true
	base.Material = Enum.Material.Metal
	base.Color = Color3.fromRGB(90, 200, 120)
	base.Position = worldWaypoints[#worldWaypoints] + Vector3.new(0, 2, 0)
	base.Parent = arena

	-- Procedurally scattered buildable tiles: any grid cell far enough from
	-- the road is a valid build spot. Keeps this working for any path
	-- shape without hand-placing tiles.
	local tilesFolder = Instance.new("Folder")
	tilesFolder.Name = "Tiles"
	tilesFolder.Parent = arena

	local tileIndex = 0
	for localX = -TILE_GRID_RANGE, TILE_GRID_RANGE, TILE_GRID_STEP do
		for localZ = -TILE_GRID_RANGE, TILE_GRID_RANGE, TILE_GRID_STEP do
			local worldPoint = Vector3.new(centerX + localX, 1, localZ)
			if distanceToPath(worldPoint, worldWaypoints) >= TILE_CLEARANCE_FROM_ROAD then
				tileIndex += 1

				local tile = Instance.new("Part")
				tile.Name = "Tile" .. tileIndex
				tile.Size = Vector3.new(5, 1, 5)
				tile.Anchored = true
				tile.Material = Enum.Material.WoodPlanks
				tile.Color = Color3.fromRGB(110, 90, 65)
				tile.Position = worldPoint
				tile:SetAttribute("Occupied", false)
				tile.Parent = tilesFolder

				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "BuildPrompt"
				prompt.ActionText = "Build"
				prompt.ObjectText = "Choose a tower"
				prompt.HoldDuration = 0.15
				prompt.MaxActivationDistance = 12
				prompt.Parent = tile
			end
		end
	end
end

-- Marks the folder as fully populated (all arenas, waypoints and tiles
-- built) so other scripts can wait for real readiness instead of just
-- the folder's existence - WaitForChild("Arenas") resolves the instant
-- this folder is created, long before the per-arena loop above actually
-- fills it in, which left tile build prompts with no server-side click
-- handler if GameLoop.server.lua reached that point first.
arenasFolder:SetAttribute("Ready", true)
