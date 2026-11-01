local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local TowerTypes = require(ReplicatedStorage.TD.TowerTypes)
local EnemyManager = require(script.Parent.EnemyManager)

local TowerManager = {}

local function upgradeCostFor(def, level)
	local levelDef = def.levels[level]
	return levelDef and levelDef.upgradeCost or 0
end

local function updatePromptText(tower, def)
	local cost = upgradeCostFor(def, tower.Level)
	local prompt = tower.UpgradePrompt
	if not prompt then
		return
	end
	if tower.Level >= #def.levels or cost <= 0 then
		prompt.ActionText = "Niveau max"
		prompt.ObjectText = def.name
	else
		prompt.ActionText = "Ameliorer"
		prompt.ObjectText = "Cout: " .. cost
	end
end

function TowerManager.Build(state, tile, towerKey)
	local def = TowerTypes[towerKey]
	if not def then
		return false, "unknown tower"
	end

	if tile:GetAttribute("Occupied") then
		return false, "tile occupied"
	end

	if state.Gold < def.baseCost then
		return false, "not enough gold"
	end

	state.Gold -= def.baseCost
	tile:SetAttribute("Occupied", true)

	local model = Instance.new("Part")
	model.Name = "Tower_" .. towerKey
	model.Shape = Enum.PartType.Cylinder
	model.Size = Vector3.new(4, 2, 2)
	model.Anchored = true
	model.Material = Enum.Material.Metal
	model.Color = def.color or Color3.fromRGB(200, 200, 200)
	model.CFrame = CFrame.new(tile.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	model.Parent = tile.Parent

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UpgradePrompt"
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 12
	prompt.Parent = model

	-- Separate key (F) from the upgrade prompt (E, Roblox's default) so
	-- both can sit on the same tower without fighting over the trigger.
	local sellPrompt = Instance.new("ProximityPrompt")
	sellPrompt.Name = "SellPrompt"
	sellPrompt.ActionText = "Vendre"
	sellPrompt.ObjectText = "Remboursement 50%"
	sellPrompt.KeyboardKeyCode = Enum.KeyCode.F
	sellPrompt.HoldDuration = 0.4
	sellPrompt.MaxActivationDistance = 12
	sellPrompt.Parent = model

	local tower = {
		Model = model,
		Tile = tile,
		Key = towerKey,
		Level = 1,
		Cooldown = 0,
		UpgradePrompt = prompt,
		SellPrompt = sellPrompt,
		TotalSpent = def.baseCost,
	}

	updatePromptText(tower, def)
	table.insert(state.Towers, tower)
	return true, tower
end

function TowerManager.Upgrade(state, tower)
	local def = TowerTypes[tower.Key]
	if not def then
		return false
	end

	local cost = upgradeCostFor(def, tower.Level)
	if tower.Level >= #def.levels or cost <= 0 then
		return false, "max level"
	end

	if state.Gold < cost then
		return false, "not enough gold"
	end

	state.Gold -= cost
	tower.Level += 1
	tower.TotalSpent += cost
	updatePromptText(tower, def)
	return true
end

local SELL_REFUND_RATE = 0.5

-- Refunds half of everything spent on this tower (base cost + upgrades),
-- frees its tile, and removes it from the run.
function TowerManager.Sell(state, tower)
	local index = table.find(state.Towers, tower)
	if not index then
		return false
	end

	state.Gold += math.floor(tower.TotalSpent * SELL_REFUND_RATE)
	tower.Tile:SetAttribute("Occupied", false)

	local buildPrompt = tower.Tile:FindFirstChild("BuildPrompt")
	if buildPrompt then
		buildPrompt.Enabled = true
	end

	tower.Model:Destroy()
	table.remove(state.Towers, index)
	return true
end

local function fireEffect(fromPos, toPos, color)
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	local length = (toPos - fromPos).Magnitude
	beam.Size = Vector3.new(0.2, 0.2, length)
	beam.CFrame = CFrame.lookAt(fromPos, toPos) * CFrame.new(0, 0, -length / 2)
	beam.Parent = workspace
	Debris:AddItem(beam, 0.1)
end

-- Advances every tower's cooldown and fires at the furthest-along enemy in
-- range (matches the source's default "first" targeting priority).
function TowerManager.Tick(state, dt, now)
	for _, tower in ipairs(state.Towers) do
		local def = TowerTypes[tower.Key]
		local levelDef = def.levels[tower.Level]

		tower.Cooldown -= dt
		if tower.Cooldown <= 0 then
			local towerPos = tower.Model.Position
			local best, bestProgress = nil, -1

			for _, enemy in ipairs(state.Enemies) do
				local dist = (enemy.Model.Position - towerPos).Magnitude
				if dist <= levelDef.range and enemy.DistanceTraveled > bestProgress then
					best = enemy
					bestProgress = enemy.DistanceTraveled
				end
			end

			if best then
				tower.Cooldown = 1 / levelDef.rate
				best.Hp -= levelDef.damage

				if levelDef.slow then
					best.SlowMult = levelDef.slow
					best.SlowUntil = now + levelDef.slowDur
				end
				if levelDef.burnDps then
					best.BurnDps = levelDef.burnDps
					best.BurnUntil = now + levelDef.burnDur
				end

				fireEffect(towerPos, best.Model.Position, def.color)

				if best.Hp <= 0 then
					EnemyManager.KillByRef(state, best)
				end

				-- Tesla-style chain: jump to the nearest not-yet-hit enemy
				-- within chainRange of the last one hit, up to chainCount
				-- total targets (including the primary one above).
				if levelDef.chainCount and levelDef.chainCount > 1 then
					local hit = { best }
					local lastPos = best.Model.Position

					for _ = 2, levelDef.chainCount do
						local nextEnemy, nextDist = nil, math.huge
						for _, enemy in ipairs(state.Enemies) do
							if not table.find(hit, enemy) then
								local dist = (enemy.Model.Position - lastPos).Magnitude
								if dist <= levelDef.chainRange and dist < nextDist then
									nextEnemy = enemy
									nextDist = dist
								end
							end
						end

						if not nextEnemy then
							break
						end

						fireEffect(lastPos, nextEnemy.Model.Position, def.color)
						nextEnemy.Hp -= levelDef.damage
						if nextEnemy.Hp <= 0 then
							EnemyManager.KillByRef(state, nextEnemy)
						end

						table.insert(hit, nextEnemy)
						lastPos = nextEnemy.Model.Position
					end
				end
			end
		end
	end
end

function TowerManager.ClearAll(state)
	for _, tower in ipairs(state.Towers) do
		tower.Tile:SetAttribute("Occupied", false)
		tower.Model:Destroy()
	end
	state.Towers = {}
end

return TowerManager
