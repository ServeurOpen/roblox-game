local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.RemoteNames)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateUpdated = remotes:WaitForChild(RemoteNames.STATE_UPDATED)

local RunState = {}

local states = {}

-- Run state is purely in-memory/per-session (not saved to the DataStore):
-- rejoining always starts a fresh run, like the original game's "New Run".
-- Only PlayerData.BestWave persists across sessions.
function RunState.New(player, arenaIndex)
	local state = {
		Player = player,
		ArenaIndex = arenaIndex,
		Gold = 200,
		Lives = 20,
		Wave = 0,
		Status = "waiting", -- waiting | spawning | gameover
		Towers = {}, -- { Model, Key, Level, Cooldown }
		Enemies = {}, -- { Model, Key, Hp, MaxHp, WaypointIndex, Progress, BaseSpeed, Dmg, Value, SlowMult, SlowUntil, BurnDps, BurnUntil }
		PendingSpawns = {}, -- { Key, Delay } with Delay counting down to 0
		NextWaveAt = 0, -- os.clock() timestamp; countdown to auto-start next wave
		LastPushAt = 0, -- os.clock() of the last state push to this player's client
		WaveKills = 0, -- reset at the start of each wave, for the end-of-wave recap
		WaveGoldEarned = 0,
		WaveLivesLost = 0,
	}
	states[player.UserId] = state
	return state
end

function RunState.Get(player)
	return states[player.UserId]
end

function RunState.Remove(player)
	states[player.UserId] = nil
end

-- Returns the internal states table directly ({userId -> state}) so the
-- game loop can iterate every active run each heartbeat without this
-- module needing to expose the loop itself.
function RunState.GetAll()
	return states
end

function RunState.Push(player)
	local state = states[player.UserId]
	if not state then
		return
	end

	-- Sent as a relative "seconds from now" duration, not a raw os.clock()
	-- timestamp: the server and client clocks aren't the same epoch, so an
	-- absolute timestamp would be meaningless on the client.
	local waveCountdown = math.max(0, state.NextWaveAt - os.clock())

	stateUpdated:FireClient(player, {
		Gold = state.Gold,
		Lives = state.Lives,
		Wave = state.Wave,
		Status = state.Status,
		WaveCountdown = waveCountdown,
	})
end

return RunState
