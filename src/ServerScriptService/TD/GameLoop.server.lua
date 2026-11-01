local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteNames = require(ReplicatedStorage.RemoteNames)
local TowerTypes = require(ReplicatedStorage.TD.TowerTypes)
local EnemyTypes = require(ReplicatedStorage.TD.EnemyTypes)
local Formulas = require(ReplicatedStorage.TD.Formulas)

local PlayerData = require(ServerScriptService.PlayerData)
local ArenaManager = require(script.Parent.ArenaManager)
local RunState = require(script.Parent.RunState)
local EnemyManager = require(script.Parent.EnemyManager)
local TowerManager = require(script.Parent.TowerManager)

-- ============================ arena construction ============================
-- Runs first, synchronously, so everything below this point can safely
-- assume Workspace.Arenas is fully built already - no separate script, no
-- cross-script readiness race to get wrong (that was the actual cause of
-- "can't build towers" surviving several earlier fixes).

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

local function buildArenas()
	-- Guard against duplicate arenas if this script somehow runs twice in
	-- an already-live server (e.g. a Rojo sync landing mid-session).
	local existingArenas = Workspace:FindFirstChild("Arenas")
	if existingArenas then
		existingArenas:Destroy()
	end

	local arenasFolder = Instance.new("Folder")
	arenasFolder.Name = "Arenas"
	arenasFolder.Parent = Workspace

	for arenaIndex = 1, ArenaManager.ARENA_COUNT do
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

		-- Purely a logical marker (no visual - a bright disc there looked ugly).
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

		-- Procedurally scattered buildable tiles: any grid cell far enough
		-- from the road is a valid build spot.
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
end

buildArenas()

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local getRunState = remotes:WaitForChild(RemoteNames.GET_RUN_STATE)
local openTowerMenu = remotes:WaitForChild(RemoteNames.OPEN_TOWER_MENU)
local requestBuild = remotes:WaitForChild(RemoteNames.REQUEST_BUILD)
local startWaveNow = remotes:WaitForChild(RemoteNames.START_WAVE_NOW)
local waveEvent = remotes:WaitForChild(RemoteNames.WAVE_EVENT)

local WAVE_CLEAR_DELAY = 3
local GAME_OVER_DELAY = 4

local function announce(player, text)
	waveEvent:FireClient(player, text)
end

local function availableEnemyKeys(wave)
	local keys = {}
	for key, def in pairs(EnemyTypes) do
		if key ~= "mini" and def.unlockWave <= wave then
			table.insert(keys, key)
		end
	end
	return keys
end

local BOSS_WAVE_INTERVAL = 10

local function startNextWave(state)
	state.Wave += 1
	local isBossWave = state.Wave % BOSS_WAVE_INTERVAL == 0

	state.PendingSpawns = {}
	if isBossWave then
		-- A single, much tougher enemy instead of the usual swarm. "boss"
		-- has unlockWave = math.huge so it never shows up in a normal
		-- wave's random pool - it's only ever spawned from here.
		table.insert(state.PendingSpawns, { Key = "boss", Delay = 0 })
	else
		local count = Formulas.EnemyCount(state.Wave)
		local interval = Formulas.SpawnInterval(state.Wave)
		local available = availableEnemyKeys(state.Wave)

		for i = 1, count do
			local key = available[math.random(1, #available)]
			table.insert(state.PendingSpawns, { Key = key, Delay = (i - 1) * interval })
		end
	end

	state.WaveKills = 0
	state.WaveGoldEarned = 0
	state.WaveLivesLost = 0
	state.Status = "spawning"
	RunState.Push(state.Player)
	announce(state.Player, isBossWave and ("Vague Boss " .. state.Wave .. " !") or ("Vague " .. state.Wave))
end

local function resetRun(state)
	state.Wave = 0
	state.Gold = 200
	state.Lives = 20
	state.Status = "waiting"
	state.NextWaveAt = os.clock() + 2
	state.WaveKills = 0
	state.WaveGoldEarned = 0
	state.WaveLivesLost = 0
	RunState.Push(state.Player)
end

local function gameOver(state)
	state.Status = "gameover"
	TowerManager.ClearAll(state)
	EnemyManager.ClearAll(state)
	RunState.Push(state.Player)
	announce(state.Player, "Partie terminee - Vague " .. state.Wave)

	local playerData = PlayerData.Get(state.Player)
	if playerData and state.Wave > playerData.BestWave then
		playerData.BestWave = state.Wave
	end

	task.delay(GAME_OVER_DELAY, function()
		if RunState.Get(state.Player) == state then
			resetRun(state)
		end
	end)
end

-- ============================ player lifecycle ============================

local function teleportToArena(player, arenaIndex)
	local cframe = ArenaManager.GetSpawnCFrame(arenaIndex)
	if not cframe then
		return
	end
	local character = player.Character or player.CharacterAdded:Wait()
	character:PivotTo(cframe)
end

local function assignArena(player, _data)
	local arenaIndex = ArenaManager.GetFreeArenaIndex()
	if not arenaIndex or not ArenaManager.ClaimArena(player, arenaIndex) then
		-- All arenas are taken; nothing to assign right now.
		return
	end

	local state = RunState.New(player, arenaIndex)
	state.NextWaveAt = os.clock() + 3
	RunState.Push(player)
	teleportToArena(player, arenaIndex)

	player.CharacterAdded:Connect(function()
		teleportToArena(player, arenaIndex)
	end)
end

PlayerData.DataLoaded:Connect(assignArena)

-- Catch up on anyone whose data finished loading before the connection
-- above was made (e.g. the local test player in Studio).
for _, player in ipairs(Players:GetPlayers()) do
	if not RunState.Get(player) then
		local data = PlayerData.Get(player)
		if data then
			assignArena(player, data)
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	local state = RunState.Get(player)
	if state then
		TowerManager.ClearAll(state)
		EnemyManager.ClearAll(state)
		ArenaManager.ReleaseArena(state.ArenaIndex)
		RunState.Remove(player)
	end
end)

-- ============================ remotes ============================

getRunState.OnServerInvoke = function(player)
	local state = RunState.Get(player)
	if not state then
		return nil
	end
	return {
		Gold = state.Gold,
		Lives = state.Lives,
		Wave = state.Wave,
		Status = state.Status,
		WaveCountdown = math.max(0, state.NextWaveAt - os.clock()),
	}
end

local function tryBuild(player, tile, towerKey, arenaIndex)
	local state = RunState.Get(player)
	if not state or state.ArenaIndex ~= arenaIndex then
		return
	end
	if type(towerKey) ~= "string" or not TowerTypes[towerKey] then
		return
	end

	local def = TowerTypes[towerKey]
	if def.unlockWave > math.max(state.Wave, 1) then
		return
	end

	local ok, towerOrErr = TowerManager.Build(state, tile, towerKey)
	if not ok then
		return
	end

	local buildPrompt = tile:FindFirstChild("BuildPrompt")
	if buildPrompt then
		buildPrompt.Enabled = false
	end

	local tower = towerOrErr
	tower.UpgradePrompt.Triggered:Connect(function(upgradePlayer)
		local upgradeState = RunState.Get(upgradePlayer)
		if not upgradeState or upgradeState.ArenaIndex ~= arenaIndex then
			return
		end

		local upgraded = TowerManager.Upgrade(upgradeState, tower)
		if upgraded then
			RunState.Push(upgradePlayer)
		end
	end)

	tower.SellPrompt.Triggered:Connect(function(sellingPlayer)
		local sellState = RunState.Get(sellingPlayer)
		if not sellState or sellState.ArenaIndex ~= arenaIndex then
			return
		end

		if TowerManager.Sell(sellState, tower) then
			RunState.Push(sellingPlayer)
		end
	end)

	RunState.Push(player)
end

requestBuild.OnServerEvent:Connect(function(player, tile, towerKey)
	if typeof(tile) ~= "Instance" or not tile:IsA("BasePart") then
		return
	end
	if tile:GetAttribute("Occupied") then
		return
	end

	local state = RunState.Get(player)
	if not state then
		return
	end
	local arena = ArenaManager.GetArenaModel(state.ArenaIndex)
	if not arena or not tile:IsDescendantOf(arena) then
		return
	end

	tryBuild(player, tile, towerKey, state.ArenaIndex)
end)

startWaveNow.OnServerEvent:Connect(function(player)
	local state = RunState.Get(player)
	if state and state.Status == "waiting" then
		startNextWave(state)
	end
end)

-- ============================ build / upgrade prompts ============================

for arenaIndex = 1, ArenaManager.ARENA_COUNT do
	local arena = ArenaManager.GetArenaModel(arenaIndex)
	local tilesFolder = arena and arena:FindFirstChild("Tiles")

	if tilesFolder then
		for _, tile in ipairs(tilesFolder:GetChildren()) do
			local buildPrompt = tile:FindFirstChild("BuildPrompt")
			if buildPrompt then
				buildPrompt.Triggered:Connect(function(player)
					local state = RunState.Get(player)
					if not state or state.ArenaIndex ~= arenaIndex then
						return
					end
					if tile:GetAttribute("Occupied") then
						return
					end

					openTowerMenu:FireClient(player, tile)
				end)
			end
		end
	end
end

-- ============================ main loop ============================

RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()

	for _, state in pairs(RunState.GetAll()) do
		if state.Status == "waiting" then
			if now >= state.NextWaveAt then
				startNextWave(state)
			end
		elseif state.Status == "spawning" then
			for i = #state.PendingSpawns, 1, -1 do
				local pending = state.PendingSpawns[i]
				pending.Delay -= dt
				if pending.Delay <= 0 then
					EnemyManager.Spawn(state, pending.Key)
					table.remove(state.PendingSpawns, i)
				end
			end

			local livesLost = EnemyManager.Step(state, dt, now)
			if livesLost > 0 then
				state.Lives -= livesLost
				state.WaveLivesLost += livesLost
				RunState.Push(state.Player)
				state.LastPushAt = now
				if state.Lives <= 0 then
					gameOver(state)
				end
			end

			if state.Status == "spawning" and #state.PendingSpawns == 0 and #state.Enemies == 0 then
				state.Status = "waiting"
				state.NextWaveAt = now + WAVE_CLEAR_DELAY
				RunState.Push(state.Player)
				state.LastPushAt = now
				announce(
					state.Player,
					string.format(
						"Vague %d terminee ! %d ennemis elimines, +%d or, %d vies perdues",
						state.Wave,
						state.WaveKills,
						state.WaveGoldEarned,
						state.WaveLivesLost
					)
				)
			elseif state.Status == "spawning" and now - state.LastPushAt >= 0.25 then
				-- Kills during combat change Gold without any other push
				-- happening, so the client's counter would otherwise look
				-- frozen until the wave ends - poll it on a short interval.
				RunState.Push(state.Player)
				state.LastPushAt = now
			end
		end

		if state.Status ~= "gameover" then
			TowerManager.Tick(state, dt, now)
		end
	end
end)
