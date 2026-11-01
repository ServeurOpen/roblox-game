local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyTypes = require(ReplicatedStorage.TD.EnemyTypes)
local Formulas = require(ReplicatedStorage.TD.Formulas)
local ArenaManager = require(script.Parent.ArenaManager)

local EnemyManager = {}

local function createModel(key, def, position)
	local part = Instance.new("Part")
	part.Name = "Enemy_" .. key
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(2.6, 2.6, 2.6)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = def.color or Color3.fromRGB(200, 70, 70)
	part.Position = position

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(40, 6)
	billboard.StudsOffset = Vector3.new(0, 2.4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	back.BorderSizePixel = 0
	back.Parent = billboard

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(90, 220, 110)
	fill.BorderSizePixel = 0
	fill.Parent = back

	return part, fill
end

function EnemyManager.Spawn(state, key)
	local def = EnemyTypes[key]
	if not def then
		return
	end

	local waypoints = ArenaManager.GetWaypoints(state.ArenaIndex)
	if #waypoints < 2 then
		return
	end

	local wave = state.Wave
	local hp = Formulas.EnemyHp(def.hp, wave)
	local speed = Formulas.EnemySpeed(def.speed, wave)
	local value = Formulas.EnemyGoldValue(def.value, wave)

	local model, fill = createModel(key, def, waypoints[1])

	local enemy = {
		Model = model,
		Fill = fill,
		Key = key,
		Hp = hp,
		MaxHp = hp,
		WaypointIndex = 2,
		DistanceTraveled = 0,
		BaseSpeed = speed,
		Dmg = def.dmg,
		Value = value,
		Splits = def.splits or false,
		SlowMult = 1,
		SlowUntil = 0,
		BurnDps = 0,
		BurnUntil = 0,
	}

	model.Parent = ArenaManager.GetArenaModel(state.ArenaIndex)
	table.insert(state.Enemies, enemy)
	return enemy
end

-- Moves every enemy belonging to this run forward by dt, applies burn
-- ticks, and returns (livesLost, killedByBase) for the caller to act on.
-- Dead-by-combat removal happens separately via Kill().
function EnemyManager.Step(state, dt, now)
	local waypoints = ArenaManager.GetWaypoints(state.ArenaIndex)
	local livesLost = 0
	local reachedBase = {}

	for i = #state.Enemies, 1, -1 do
		local enemy = state.Enemies[i]

		if enemy.BurnUntil > now and enemy.BurnDps > 0 then
			enemy.Hp -= enemy.BurnDps * dt
		end

		if enemy.Hp <= 0 then
			EnemyManager.Kill(state, i, true)
		else
			local speedMult = (enemy.SlowUntil > now) and enemy.SlowMult or 1
			local moveDist = enemy.BaseSpeed * speedMult * dt
			enemy.DistanceTraveled += moveDist
			local pos = enemy.Model.Position

			while moveDist > 0 and enemy.WaypointIndex <= #waypoints do
				local target = waypoints[enemy.WaypointIndex]
				local toTarget = target - pos
				local dist = toTarget.Magnitude

				if dist <= moveDist then
					pos = target
					moveDist -= dist
					enemy.WaypointIndex += 1
				else
					pos += toTarget.Unit * moveDist
					moveDist = 0
				end
			end

			enemy.Model.Position = pos

			if enemy.WaypointIndex > #waypoints then
				livesLost += enemy.Dmg
				table.insert(reachedBase, i)
			else
				local pct = math.clamp(enemy.Hp / enemy.MaxHp, 0, 1)
				enemy.Fill.Size = UDim2.fromScale(pct, 1)
			end
		end
	end

	for _, index in ipairs(reachedBase) do
		local enemy = state.Enemies[index]
		if enemy then
			enemy.Model:Destroy()
			table.remove(state.Enemies, index)
		end
	end

	return livesLost
end

-- Removes an enemy by index, granting gold and spawning splits if it has
-- splits=true. grantGold defaults to true (false is reserved for future
-- use, e.g. an enemy removed without a kill credit).
function EnemyManager.Kill(state, index, grantGold)
	local enemy = state.Enemies[index]
	if not enemy then
		return
	end

	if grantGold ~= false then
		state.Gold += enemy.Value
	end

	local deathPosition = enemy.Model.Position
	local deathWaypointIndex = enemy.WaypointIndex
	local deathDistanceTraveled = enemy.DistanceTraveled

	enemy.Model:Destroy()
	table.remove(state.Enemies, index)

	if enemy.Splits then
		for _ = 1, 3 do
			local mini = EnemyManager.Spawn(state, "mini")
			if mini then
				mini.Model.Position = deathPosition
				mini.WaypointIndex = deathWaypointIndex
				mini.DistanceTraveled = deathDistanceTraveled
			end
		end
	end
end

-- Convenience for callers (tower combat) that hold an enemy reference
-- instead of its index into state.Enemies.
function EnemyManager.KillByRef(state, enemyRef)
	local index = table.find(state.Enemies, enemyRef)
	if index then
		EnemyManager.Kill(state, index, true)
	end
end

function EnemyManager.ClearAll(state)
	for _, enemy in ipairs(state.Enemies) do
		enemy.Model:Destroy()
	end
	state.Enemies = {}
end

return EnemyManager
