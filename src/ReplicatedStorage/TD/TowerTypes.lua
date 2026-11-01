-- Tower stats ported from the original Tower Defense Infini (HTML/JS)
-- design. v1 ships 4 of the 9 original towers, all as single-target for
-- now (the source's Archer is actually a piercing line/"rectangle" AoE;
-- simplified here to single-target until a later pass adds that back).
-- Costs, ranges, damage, rates and upgrade costs are taken as-is from the
-- source's TOWER_TYPES so the original balance carries over.
return {
	cannon = {
		name = "Canon",
		baseCost = 50,
		unlockWave = 1,
		color = Color3.fromRGB(159, 176, 208),
		levels = {
			{ range = 26, damage = 14, rate = 1.4, upgradeCost = 60 },
			{ range = 30, damage = 24, rate = 1.6, upgradeCost = 110 },
			{ range = 34, damage = 40, rate = 1.9, upgradeCost = 0 },
		},
	},
	archer = {
		name = "Tour Archer",
		baseCost = 75,
		unlockWave = 5,
		color = Color3.fromRGB(201, 163, 91),
		levels = {
			{ range = 30, damage = 10, rate = 1.2, upgradeCost = 70 },
			{ range = 34, damage = 16, rate = 1.35, upgradeCost = 130 },
			{ range = 38, damage = 24, rate = 1.5, upgradeCost = 0 },
		},
	},
	frost = {
		name = "Tour de Glace",
		baseCost = 100,
		unlockWave = 10,
		color = Color3.fromRGB(95, 201, 255),
		levels = {
			{ range = 24, damage = 6, rate = 1.1, slow = 0.82, slowDur = 1.6, upgradeCost = 100 },
			{ range = 27, damage = 9, rate = 1.2, slow = 0.76, slowDur = 2.0, upgradeCost = 170 },
			{ range = 30, damage = 13, rate = 1.3, slow = 0.68, slowDur = 2.4, upgradeCost = 0 },
		},
	},
	fire = {
		name = "Tour de Feu",
		baseCost = 120,
		unlockWave = 20,
		color = Color3.fromRGB(255, 123, 61),
		levels = {
			{ range = 22, damage = 8, rate = 1.3, burnDps = 8, burnDur = 2.5, upgradeCost = 120 },
			{ range = 24, damage = 12, rate = 1.4, burnDps = 14, burnDur = 2.8, upgradeCost = 190 },
			{ range = 27, damage = 18, rate = 1.6, burnDps = 22, burnDur = 3.2, upgradeCost = 0 },
		},
	},
}
