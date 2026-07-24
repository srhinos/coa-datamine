
local T = {
	name = "Hearthstone",
	cvar = "npeHearthstoneTutorial",
	classless = true,

	quests = {
		1903541
	},

	sequences = {
		["QUEST_ACCEPTED"] = {
			"HEARTHSTONES1",
			"HEARTHSTONES2",
		}
	}
}

NPE:RegisterTutorial(T)

NPEPopups["HEARTHSTONES1"] = {
	cvar = T.cvar,
	cvarBit = T:NextBit(),
	offsetX = -50,
	offsetY = 50,
	point = "RIGHT",
	relativeTo="WatchFrame",
	relativePoint="LEFT",
	image1 = {
		atlas = "npe-hearthstone",
		width = 155,
		height = 180,
	},
	questFinish = 1903541,
}

NPEPopups["HEARTHSTONES2"] = {
	cvar = T.cvar,
	cvarBit = T:NextBit(),
	offsetX = -50,
	offsetY = -50,
	point = "RIGHT",
	relativeTo="WatchFrame",
	relativePoint="LEFT",
	image1 = {
		atlas = "npe-hearthstone-cast",
		width = 185,
		height = 220,
	},
}