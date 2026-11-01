-- Pet shop catalogue. Every owned+equipped pet adds its energyPerSec to the
-- player's passive income (ticked server-side once per second). "starter"
-- is free and auto-granted to every new player so the loop isn't empty on
-- their very first click.
return {
	starter = {
		name = "Chaton Etincelle",
		cost = 0,
		energyPerSec = 0.5,
		color = Color3.fromRGB(235, 220, 160),
		order = 1,
	},
	rock = {
		name = "Pierre Vivante",
		cost = 50,
		energyPerSec = 1.5,
		color = Color3.fromRGB(140, 140, 150),
		order = 2,
	},
	flame = {
		name = "Flammy",
		cost = 250,
		energyPerSec = 5,
		color = Color3.fromRGB(255, 120, 60),
		order = 3,
	},
	crystal = {
		name = "Cristal Luisant",
		cost = 1000,
		energyPerSec = 16,
		color = Color3.fromRGB(110, 210, 255),
		order = 4,
	},
	dragon = {
		name = "Dragonnet",
		cost = 5000,
		energyPerSec = 60,
		color = Color3.fromRGB(190, 70, 220),
		order = 5,
	},
}
