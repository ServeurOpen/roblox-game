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

local function startNextWave(state)
	state.Wave += 1
	local count = Formulas.EnemyCount(state.Wave)
	local interval = Formulas.SpawnInterval(state.Wave)
	local available = availableEnemyKeys(state.Wave)

	state.PendingSpawns = {}
	for i = 1, count do
		local key = available[math.random(1, #available)]
		table.insert(state.PendingSpawns, { Key = key, Delay = (i - 1) * interval })
	end

	state.WaveKills = 0
	state.WaveGoldEarned = 0
	state.WaveLivesLost = 0
	state.Status = "spawning"
	RunState.Push(state.Player)
	announce(state.Player, "Vague " .. state.Wave)
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

Workspace:WaitForChild("Arenas")
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
