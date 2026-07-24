local _, NPE = ... 

local Const = {}
NPE.Const = Const

Const.PopupPriority = {
	MAX = 99,
	HIGH = 3,
	MEDIUM = 2,
	LOW = 1,
}

Const.Tutorials = {
	CHARACTER_PANEL_TUTORIAL			= "CHARACTER_PANEL_TUTORIAL",
	EQUIP_ITEMS_TUTORIAL 				= "EQUIP_ITEMS_TUTORIAL",
	LOOT_WINDOW_TUTORIAL				= "LOOT_WINDOW_TUTORIAL",
	LOOT_CORPSE_TUTORIAL 				= "LOOT_CORPSE_TUTORIAL",
	WORLD_MAP_TUTORIAL 					= "WORLD_MAP_TUTORIAL",
	CAST_TUTORIAL 						= "CAST_TUTORIAL",
	MOVE_TUTORIAL					 	= "MOVE_TUTORIAL",
	XP_TUTORIAL							= "XP_TUTORIAL",
	STARTING_QUEST_1					= "STARTING_QUEST_1",
	STARTING_QUEST_2					= "STARTING_QUEST_2",
	STARTING_AREA_CONTROLLER 			= "STARTING_AREA_CONTROLLER",
    KILL_AREA_CONTROLLER                = "KILL_AREA_CONTROLLER",
    USE_MOUNT_TUTORIAL                  = "USE_MOUNT_TUTORIAL",
    MOUNT_CHARACTER_PANEL_TUTORIAL      = "MOUNT_CHARACTER_PANEL_TUTORIAL",
    FULL_BAGS_TUTORIAL                  = "FULL_BAGS_TUTORIAL",
    KEYS_TUTORIAL                       = "KEYS_TUTORIAL",
    RES_SAFE_ZONE_TUTORIAL              = "RES_SAFE_ZONE_TUTORIAL",
    USE_BAGS_TUTORIAL                   = "USE_BAGS_TUTORIAL",
    GREYED_EXCLAMATION_TUTORIAL         = "GREYED_EXCLAMATION_TUTORIAL",
    GREYED_QUESTION_TUTORIAL            = "GREYED_QUESTION_TUTORIAL",
    SKILL_CARD_TUTORIAL                 = "SKILL_CARD_TUTORIAL",
    SKILL_CARD_TUTORIAL_CLEAR_START     = "SKILL_CARD_TUTORIAL_CLEAR_START",
    AUCTION_HOUSE_DEPOSIT               = "AUCTION_HOUSE_DEPOSIT",
}

Const.NorthshireQuest1 					= 783
Const.NorthshireQuest2 					= 7
Const.ValleyOfTrialsQuest2 				= 788
Const.ValleyOfTrialsQuest1 				= 4641
Const.ShadowGraveQuest1 				= 363
Const.ShadowGraveQuest2 				= 364
Const.AmmenValeQuest1 					= 9279
Const.AmmenValeQuest2 					= 9280
Const.ColdRidgeQuest1 					= 179
Const.ShadowGlenQuest1 					= 456
Const.NarcheQuest1 						= 747
Const.SunstriderQuest1 					= 8325

Const.StartingQuests1 = {
	Const.SunstriderQuest1,
	Const.NarcheQuest1,
	Const.ShadowGraveQuest1,
	Const.ValleyOfTrialsQuest1,
	Const.NorthshireQuest1,
	Const.ColdRidgeQuest1,
	Const.ShadowGlenQuest1,
	Const.AmmenValeQuest1,
}

Const.StartingQuests2 = {
	Const.ValleyOfTrialsQuest2,
	Const.ShadowGraveQuest2,
	Const.AmmenValeQuest2,
	Const.NorthshireQuest2,
}

-- use /measure to get the distance between two points
-- use /run local x,y,_,m = GetCurrentPlayerPosition() Internal_CopyToClipboard(format("%.4f, %.4f, %s", x, y, m))
Const.StartingAreas = {
	{-8949.1113, -128.6298, 0, 400, {Const.NorthshireQuest1, Const.NorthshireQuest2}}, -- Northshire
	{ -609.6086, -4253.5493, 1, 560, {Const.ValleyOfTrialsQuest1, Const.ValleyOfTrialsQuest2}}, -- Valley of trials
	{1664.4431, 1677.8247, 0, 644, {Const.ShadowGraveQuest1, Const.ShadowGraveQuest2}}, -- Deathkneel
	{-2900.8257, -256.7517, 1, 416, {Const.NarcheQuest1}}, -- Red cloud mesa
	{10348.7256, -6369.3452, 530, 521, {Const.SunstriderQuest1}}, -- Sunstrider Isle
	{-3962.1687, -13930.7295, 530, 800, {Const.AmmenValeQuest1, Const.AmmenValeQuest2}}, -- Ammen Vale
	{-6231.7700, 332.9930, 0, 600, {Const.ColdRidgeQuest1}}, -- Coldridge
	{10323.3525, 827.1478, 1, 500, {Const.ShadowGlenQuest1}}, -- Shadowglen
}

Const.KillAreas = {
    {-8778.2324, -187.5988, 0, 80, Const.NorthshireQuest2},
    {-6345.7900, 411.2033, 0, 100, Const.ColdRidgeQuest1},
    {-466.1274, -4308.1245, 1, 200, Const.ValleyOfTrialsQuest2},
    {1947.6378, 1571.5997, 0, 80, Const.ShadowGraveQuest2},
    {1731.4197, 1627.9725, 0, 72, Const.ShadowGraveQuest1},
    {-2992.9744, -379.3837, 1, 100, Const.NarcheQuest1},
    {10303.7715, -6323.0127, 530, 100, Const.SunstriderQuest1},
    {-3965.1707, -13708.5352, 530, 80, Const.AmmenValeQuest2},
    {110313.1182, 834.2576, 1, 100, Const.ShadowGlenQuest1},
}

-- TODO: Localize
Const.QuestGivers = {
	[Const.SunstriderQuest1] 			= {objective = NPE_QUEST_GIVERS_SUNSTRIDERQUEST1 or "|cffffd100Talk|r to Magistrix Erona", ID = 15278},
	[Const.NarcheQuest1] 				= {objective = NPE_QUEST_GIVERS_NARCHEQUEST1 or "|cffffd100Talk|r to Grull Hawkwind", ID = 2980},
	[Const.ShadowGraveQuest1] 			= {objective = NPE_QUEST_GIVERS_SHADOWGRAVEQUEST1 or "|cffffd100Talk|r to Undertaker Mordo", ID = 1568},
	[Const.ValleyOfTrialsQuest1]	 	= {objective = NPE_QUEST_GIVERS_VALLEYOFTRIALSQUEST1 or "|cffffd100Talk|r to Kaltunk", ID = 10176},
	[Const.NorthshireQuest1]			= {objective = NPE_QUEST_GIVERS_NORTHSHIREQUEST1 or "|cffffd100Talk|r to Deputy Willem", ID = 823},
	[Const.ColdRidgeQuest1] 			= {objective = NPE_QUEST_GIVERS_COLDRIDGEQUEST1 or "|cffffd100Talk|r to Sten Stoutarm", ID = 658},
	[Const.ShadowGlenQuest1]			= {objective = NPE_QUEST_GIVERS_SHADOWGLENQUEST1 or "|cffffd100Talk|r to Conservator Ilthalaine", ID = 2079},
	[Const.AmmenValeQuest1]			 	= {objective = NPE_QUEST_GIVERS_AMMENVALEQUEST1 or "|cffffd100Talk|r to Megelon", ID = 16475},

	[Const.ValleyOfTrialsQuest2]		= {objective = NPE_QUEST_GIVERS_VALLEYOFTRIALSQUEST2 or "|cffffd100Talk|r to Gornek", ID = 3143},
	[Const.ShadowGraveQuest2]			= {objective = NPE_QUEST_GIVERS_SHADOWGRAVEQUEST2 or "|cffffd100Talk|r to Shadow Priest Sarvis", ID = 1569},
	[Const.AmmenValeQuest2]			 	= {objective = NPE_QUEST_GIVERS_AMMENVALEQUEST2 or "|cffffd100Talk|r to Proenitus", ID = 16477},
	[Const.NorthshireQuest2]			= {objective = NPE_QUEST_GIVERS_NORTHSHIREQUEST2 or "|cffffd100Talk|r to Marshal McBride", ID = 197},
}

Const.Quest1MinimapCompletionHint = {
	--[[[Const.SunstriderQuest1] = true,
	[Const.NarcheQuest1] = true,
	[Const.ShadowGraveQuest1] = true,
	[Const.ValleyOfTrialsQuest1] = true,
	[Const.NorthshireQuest1] = true,
	[Const.ColdRidgeQuest1] = true,
	[Const.ShadowGlenQuest1] = true,
	[Const.AmmenValeQuest1] = true,]]--
}

Const.Quest2MinimapCompletionHint = {
    --[[[Const.ShadowGraveQuest2] = true,
    [Const.ValleyOfTrialsQuest2] = true,
    [Const.NorthshireQuest2] = true,
    [Const.AmmenValeQuest2] = true,]]--
}

Const.KillAreaObjectives = {
    [Const.SunstriderQuest1]            = {objective = NPE_KILL_AREA_OBJECTIVES_SUNSTRIDERQUEST1 or "Kill |cffFFFF00Mana Wyrms|r\nRight Click when near a creature to Auto-Attack it", ID = 15274, fontSize=12},
    [Const.NarcheQuest1]                = {objective = NPE_KILL_AREA_OBJECTIVES_NARCHEQUEST1 or "Collect |cffFFFF00Plainstrider Feathers|r and |cffFFFF00Plainstrider Meat|r", ID = 2955},
    [Const.ColdRidgeQuest1]             = {objective = NPE_KILL_AREA_OBJECTIVES_COLDRIDGEQUEST1 or "Kill |cffFFFF00Ragged Young Wolves|r to collect |cffFFFF00Tough Wolf Meat|r\nRight Click when near a creature to Auto-Attack it", ID = 705, fontSize=12},
    [Const.ShadowGlenQuest1]            = {objective = NPE_KILL_AREA_OBJECTIVES_SHADOWGLENQUEST1 or "Kill |cffFFFF00Young Nightsabers|r and |cffFFFF00Young Thistle Boars|r\nRight Click when near a creature to Auto-Attack it", ID = 2031, fontSize=12},
    [Const.ValleyOfTrialsQuest2]        = {objective = NPE_KILL_AREA_OBJECTIVES_VALLEYOFTRIALSQUEST2 or "Kill |cffFFFF00Mottled Boar|r\nRight Click when near a creature to Auto-Attack it", ID = 3098, fontSize=12},
    [Const.ShadowGraveQuest2]           = {objective = NPE_KILL_AREA_OBJECTIVES_SHADOWGRAVEQUEST2 or "Kill |cffFFFF00Mindless Zombies|r and  |cffFFFF00Wretched Ghouls|r\nRight Click when near a creature to Auto-Attack it", ID = 1501, fontSize=12},
    [Const.AmmenValeQuest2]             = {objective = NPE_KILL_AREA_OBJECTIVES_AMMENVALEQUEST2 or "Kill |cffFFFF00Vale Moths|r to collect |cffFFFF00Vial of Moth Blood|r\nRight Click when near a creature to Auto-Attack it", ID = 16520, fontSize=12},
    [Const.NorthshireQuest2]            = {objective = NPE_KILL_AREA_OBJECTIVES_NORTHSHIREQUEST2 or "Kill |cffFFFF00Kobold Vermin|r\nRight Click when near a creature to Auto-Attack it", ID = 6, fontSize=12},
    [Const.ShadowGraveQuest1]           = {objective = NPE_KILL_AREA_OBJECTIVES_SHADOWGRAVEQUEST1 or "Kill |cffFFFF00Duskbats|r\nRight Click when near a creature to Auto-Attack it", ID = 1512, fontSize=12},
}

Const.Quest1Objectives = {
	[Const.ValleyOfTrialsQuest1]	 	= {objective = NPE_QUEST1_OBJECTIVES_VALLEYOFTRIALSQUEST1 or "|cffFFFF00Talk|r to Gornek", ID = 3143},
	[Const.NorthshireQuest1]			= {objective = NPE_QUEST1_OBJECTIVES_NORTHSHIREQUEST1 or "|cffFFFF00Talk|r to Marshal McBride", ID = 197},
	[Const.AmmenValeQuest1]			 	= {objective = NPE_QUEST1_OBJECTIVES_AMMENVALEQUEST1 or "|cffFFFF00Talk|r to Proenitus", ID = 16477},
}

Const.Quest1Completions = {
	[Const.SunstriderQuest1] 			= {objective = NPE_QUEST1_COMPLETIONS_SUNSTRIDERQUEST1 or "Return to |cffFFFF00Magistrix Erona|r and turn in your quest.", ID = 15278, fontSize=14},
	[Const.NarcheQuest1] 				= {objective = NPE_QUEST1_COMPLETIONS_NARCHEQUEST1 or "Return to |cffFFFF00Grull Hawkwind|r and turn in your quest", ID = 2980, fontSize=14},
	[Const.ShadowGraveQuest1] 			= {objective = NPE_QUEST1_COMPLETIONS_SHADOWGRAVEQUEST1 or "Talk to |cffFFFF00Shadow Priest Sarvis|r and turn in your quest", ID = 1569, fontSize=14},
	[Const.ValleyOfTrialsQuest1]	 	= {objective = NPE_QUEST1_COMPLETIONS_VALLEYOFTRIALSQUEST1 or "|cffFFFF00Talk|r to Gornek", ID = 3143},
	[Const.NorthshireQuest1]			= {objective = NPE_QUEST1_COMPLETIONS_NORTHSHIREQUEST1 or "|cffFFFF00Talk|r to Marshal McBride", ID = 197},
	[Const.ColdRidgeQuest1] 			= {objective = NPE_QUEST1_COMPLETIONS_COLDRIDGEQUEST1 or "Return to |cffFFFF00Sten Stoutarm|r and turn in your quest", ID = 658, fontSize=14},
	[Const.ShadowGlenQuest1]			= {objective = NPE_QUEST1_COMPLETIONS_SHADOWGLENQUEST1 or "Return to |cffFFFF00Conservator Ilthalaine|r and turn in your quest", ID = 2079, fontSize=14},
	[Const.AmmenValeQuest1]			 	= {objective = NPE_QUEST1_COMPLETIONS_AMMENVALEQUEST1 or "|cffFFFF00Talk|r to Proenitus", ID = 16477},
}

Const.Quest2Completions = {
	[Const.ValleyOfTrialsQuest2]		= {objective = NPE_QUEST2_COMPLETIONS_VALLEYOFTRIALSQUEST2 or "Return to |cffFFFF00Gornek|r and turn in your quest", ID = 3143, fontSize=14},
	[Const.ShadowGraveQuest2]			= {objective = NPE_QUEST2_COMPLETIONS_SHADOWGRAVEQUEST2 or "Return to |cffFFFF00Shadow Priest Sarvis|r and turn in your quest", ID = 1569, fontSize=14},
	[Const.AmmenValeQuest2]			 	= {objective = NPE_QUEST2_COMPLETIONS_AMMENVALEQUEST2 or "Return to |cffFFFF00Proenitus|r and turn in your quest", ID = 16477, fontSize=14},
	[Const.NorthshireQuest2]			= {objective = NPE_QUEST2_COMPLETIONS_NORTHSHIREQUEST2 or "Return to |cffFFFF00Marshal McBride|r and turn in your quest", ID = 197, fontSize=14},
}

Const.WorldMapTutorialQuests = {
	15, -- NorthshireQuest3
    233, -- ColdridgeQuest2
    457, -- ShadowGlenQuest2
    9283, -- ammenvale quest 4
    8327, -- SunstriderQuest4
    789, -- orc quest 3
    750, -- tauren quest 2
    3901, -- undead quest 3
}

Const.CharacterPanelSlots = {
    [1] = "CharacterHeadSlot",
    [2] = "CharacterNeckSlot",
    [3] = "CharacterShoulderSlot",
    [15] = "CharacterBackSlot",
    [5] = "CharacterChestSlot",
    [4] = "CharacterShirtSlot",
    [19] = "CharacterTabardSlot",
    [9] = "CharacterWristSlot",
    [10] = "CharacterHandsSlot",
    [6] = "CharacterWaistSlot",
    [7] = "CharacterLegsSlot",
    [8] = "CharacterFeetSlot",
    [11] = "CharacterFinger0Slot",
    [12] = "CharacterFinger1Slot",
    [13] = "CharacterTrinket0Slot",
    [14] = "CharacterTrinket1Slot",
    [16] = "CharacterMainHandSlot",
    [17] = "CharacterSecondaryHandSlot",
    [18] = "CharacterRangedSlot"
}

Const.ActionBars = { "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft", "BonusActionBarFrame"}

Const.StartingAreaCreatures = {
    -- NORTHSHIRE
    [299] = true,
    [6] = true,
    [257] = true,
    [69] = true,
    [80] = true,
    [38] = true,
    [103] = true,
    -- VALLEY_OF_TRIALS
    [3098] = true,
    [111810] = true,
    [113224] = true,
    [113304] = true,
    -- SHADOW_GRAVE
    [1502] = true,
    [1501] = true,
    [1512] = true,
    [1890] = true,
    [1504] = true,
    -- AMMENVALE_START
    [16520] = true,
    [16516] = true,
    [16537] = true, 
    [16518] = true,
    [16517] = true,
    -- COLDRIDGE_START
    [705] = true,
    [708] = true,
    [724] = true,
    [707] = true,
    [706] = true,
    -- SHADOWGLEN
    [2031] = true,
    [1984] = true,
    [1988] = true,
    -- NARACHE
    [2955] = true,
    [2961] = true,
    [2966] = true,
    [2952] = true,
    -- SUNSTRIDER
    [15274] = true,
    [15366] = true,
    [15294] = true,
    [15273] = true,
    [15271] = true,
}

Const.DamageSpells = { -- probably remove dots from this list. SIMPLEST damage spells
    [5176] = true,
    [8921] = true,
    [686] = true,
    [1978] = true,
    [3044] = true,
    [1495] = true,
    [2973] = true,
    [2136] = true,
    [133] = true,
    [5143] = true,
    [116] = true,
    [53408] = true,
    [20271] = true,
    [585] = true,
    --[589] = true, -- shadow word: pain
    [1752] = true,
    [1776] = true,
    [403] = true,
    [8042] = true,
    --[980] = true, -- curse of agony
    --[172] = true, -- corruption
    [686] = true,
    [348] = true,
    [1715] = true,
    [78] = true,
    [772] = true,
    [34428] = true,
    [818003] = true,
    [818014] = true,
    [818004] = true,
}

Const.HealingSpells = {
    [5185] = true,
    [774] = true,
    [635] = true,
    [2050] = true,
    [139] = true,
    [331] = true,
}