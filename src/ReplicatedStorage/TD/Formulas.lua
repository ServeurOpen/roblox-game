-- Wave scaling formulas, copied as-is from the original game's JS so wave
-- difficulty/economy pacing carries over.
local Formulas = {}

-- 1 + (wave-1)*0.16 + (wave-1)^1.4*0.008
function Formulas.ScaleFactor(wave)
	return 1 + (wave - 1) * 0.16 + (wave - 1) ^ 1.4 * 0.008
end

-- min(8 + floor(wave*1.5), 44)
function Formulas.EnemyCount(wave)
	return math.min(8 + math.floor(wave * 1.5), 44)
end

-- max(0.32, 1.05 - wave*0.015) seconds between spawns
function Formulas.SpawnInterval(wave)
	return math.max(0.32, 1.05 - wave * 0.015)
end

function Formulas.EnemyHp(baseHp, wave)
	return baseHp * Formulas.ScaleFactor(wave)
end

-- speed scales a little with wave too: base * (0.9 + min(0.35, wave*0.008))
function Formulas.EnemySpeed(baseSpeed, wave)
	return baseSpeed * (0.9 + math.min(0.35, wave * 0.008))
end

function Formulas.EnemyGoldValue(baseValue, wave)
	return math.round(baseValue * Formulas.ScaleFactor(wave) ^ 0.55)
end

return Formulas
