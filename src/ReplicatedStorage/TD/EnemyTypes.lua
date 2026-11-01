-- Enemy stats ported from the original game's ENEMY_TYPES. v1 ships the
-- first 4 non-boss types (the ones unlocked by wave 8 in the source), to
-- keep the first playable slice scoped. dmg = lives lost if it reaches
-- the base. value = base gold reward on kill. Colors carried over from
-- the source's palette for each type.
return {
	normal = {
		name = "Rodeur",
		hp = 40,
		speed = 18,
		value = 2,
		dmg = 1,
		unlockWave = 1,
		color = Color3.fromRGB(154, 166, 196),
	},
	fast = {
		name = "Furtif Rapide",
		hp = 24,
		speed = 34,
		value = 2.5,
		dmg = 1,
		unlockWave = 6,
		color = Color3.fromRGB(244, 224, 77),
	},
	tank = {
		name = "Blinde",
		hp = 150,
		speed = 12,
		value = 4.5,
		dmg = 2,
		unlockWave = 7,
		color = Color3.fromRGB(138, 74, 74),
	},
	splitter = {
		name = "Diviseur",
		hp = 60,
		speed = 19,
		value = 3.5,
		dmg = 1,
		splits = true,
		unlockWave = 8,
		color = Color3.fromRGB(177, 95, 214),
	},
	mini = {
		name = "Eclat",
		hp = 18,
		speed = 24,
		value = 1.25,
		dmg = 1,
		-- Only ever spawned by a splitter's death, never picked for a wave.
		unlockWave = math.huge,
		color = Color3.fromRGB(215, 156, 232),
	},
}
