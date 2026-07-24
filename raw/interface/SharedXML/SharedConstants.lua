function IsExtensionsLoaded()
	return GetSecureAddons ~= nil
end

function CallErrorHandler(...)
	return geterrorhandler()(...)
end

function nop() end
noop = nop

if not C_Realm.IsDevelopment() then
	dprint = nop
	aprint = nop
	dfunc = nop
end

local function secureexecutenext(tbl, prev, func, ...)
	local key, value = next(tbl, prev)

	if key ~= nil then
		local status, err = pcall(func, key, value, ...)
		if not status then
			CallErrorHandler(err)
		end
	end

	return key
end

function secureexecuterange(tbl, func, ...)
	local key

	repeat
		key = securecall(secureexecutenext, tbl, key, func, ...)
	until key == nil
end

function IsCustomClass(unit)
	if InGlue() then
		return false
	end
	if not unit then unit = "player" end
	return bit.contains(Enum.ClassMask.COA, UnitClassMask(unit))
end

function IsDefaultClass(unit)
	if InGlue() then
		return false
	end
	if not unit then unit = "player" end
	return bit.contains(Enum.ClassMask.DEFAULT, UnitClassMask(unit))
end

function IsHeroClass(unit)
	if InGlue() then
		return false
	end
	if not unit then unit = "player" end
	return select(2, UnitClassBase(unit)) == "HERO"
end

securecallfunction = securecall

function GetClientVersion()
	local dbcDate, dbcTime, patchVersion, patchUpToDate = "NO DLL", "", "Not Available", true
	if IsExtensionsLoaded and IsExtensionsLoaded() then
		patchUpToDate = true
		local dbcPatchSpell = GetSpellDescription(456456)
		if dbcPatchSpell then
			dbcDate, dbcTime = dbcPatchSpell:match("Your current patch was made on (.*) at (.*). If your patch is out")
		else
			dbcDate = "UNKNOWN"
			dbcTime = ""
		end

		if IsGMClient then
			patchVersion = "Development Client"
		elseif PTR_CLIENT then
			patchVersion = "PTR Client"
		end
	end

	return dbcDate or "", dbcTime or "", patchVersion or "", patchUpToDate or false
end

function OnEventToMethod(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end
--
-- Colors
--
TOOLTIP_DEFAULT_COLOR = CreateColor(1, 1, 1)
TOOLTIP_DEFAULT_BACKGROUND_COLOR = CreateColor(0.09, 0.09, 0.09)

NORMAL_FONT_COLOR = CreateColor(1, 0.82, 0)
NORMAL_FONT_DESATURATED = CreateColor(0.75, 0.65, .25)
HIGHLIGHT_FONT_COLOR = CreateColor(1, 1, 1)
DISABLED_FONT_COLOR = CreateColor(0.5, 0.5, 0.5)
RED_FONT_COLOR = CreateColor(1, 0.1, 0.1)
GREEN_FONT_COLOR = CreateColor(0.1, 1, 0.1)
GRAY_FONT_COLOR = CreateColor(0.5, 0.5, 0.5)
WHITE_FONT_COLOR = CreateColor(1, 1, 1)
YELLOW_FONT_COLOR = CreateColor(1, 1, 0)
LIGHTYELLOW_FONT_COLOR = CreateColor(1, 1, 0.6)
ORANGE_FONT_COLOR = CreateColor(1, 0.5, 0.25)
BRIGHTBLUE_FONT_COLOR = CreateColor(0.73, 1, 1)
PASSIVE_SPELL_FONT_COLOR = CreateColor(0.77, 0.64, 0)
NEW_FEATURE_SHADOW_COLOR = CreateColor(0.32, 0.5, 1.0)
SPELL_LINK_COLOR = CreateColor(0.44, 0.84, 1)
TRANSMOG_UNLOCK_COLOR = CreateColor(1, 0.5, 1)
APPEARANCE_NOT_COLLECTED_COLOR = CreateColor(0.534, 0.667, 1)
SPELL_DISALLOWED_COLOR = CreateColor(1, 0.1, 0.1)
LINK_COLOR = CreateColor(0, 0.98, 0.96)

KYRIAN_BLUE_COLOR = CreateColor(0.1647, 0.6353, 1.0)
VENTHYR_RED_COLOR = CreateColor(0.8941, 0.0510, 0.0549)
NIGHT_FAE_BLUE_COLOR = CreateColor(0.5020, 0.7098, 0.9922)
NECROLORD_GREEN_COLOR = CreateColor(0.0902, 0.7843, 0.3922)

ASCENSION_PRIMARY_COLOR = CreateColor(0.97, 0.21, 0)
ASCENSION_SECONDARY_COLOR = CreateColor(0.99, 0.54, 0)

NORMAL_FONT_COLOR_CODE = "|c" .. NORMAL_FONT_COLOR.colorStr
HIGHLIGHT_FONT_COLOR_CODE = "|c" .. HIGHLIGHT_FONT_COLOR.colorStr
RED_FONT_COLOR_CODE = "|c" .. RED_FONT_COLOR.colorStr
GREEN_FONT_COLOR_CODE = "|c" .. GREEN_FONT_COLOR.colorStr
GRAY_FONT_COLOR_CODE = "|c" .. GRAY_FONT_COLOR.colorStr
YELLOW_FONT_COLOR_CODE = "|c" .. YELLOW_FONT_COLOR.colorStr
LIGHTYELLOW_FONT_COLOR_CODE = "|c" .. LIGHTYELLOW_FONT_COLOR.colorStr
ORANGE_FONT_COLOR_CODE = "|c" .. ORANGE_FONT_COLOR.colorStr
FONT_COLOR_CODE_CLOSE = "|r";

REALM_ONLINE_COLOR = CreateColor(0.4, 1, 0.4)
REALM_OFFLINE_COLOR = CreateColor(0.7, 0.7, 0.7)
REALM_DEV_COLOR = CreateColor(0, 0.8, 1)
REALM_INVALID_COLOR = CreateColor(1, 0.2, 0.2)
REALM_PURCHASE_COLOR = CreateColor(1, 0.8, 0.4)

WHISPER_FONT_COLOR = CreateColor(1, 0.5, 1)

ITEM_QUALITY_COLORS = {}
-- idk why but the old UIParent version included -1, 8 and 9
ITEM_QUALITY_COLORS[-1] = CreateColor(1, 1, 1) -- invalid (White)
ITEM_QUALITY_COLORS[0] = CreateColor(0.62, 0.62, 0.62) -- Poor (Grey)
ITEM_QUALITY_COLORS[1] = CreateColor(1, 1, 1) -- Common (White)
ITEM_QUALITY_COLORS[2] = CreateColor(0.12, 1, 0) -- Uncommon (Green)
ITEM_QUALITY_COLORS[3] = CreateColor(0, 0.44, 0.87) -- Rare (Blue)
ITEM_QUALITY_COLORS[4] = CreateColor(0.64, 0.21, 0.93) -- Epic (Purple)
ITEM_QUALITY_COLORS[5] = CreateColor(1, 0.5, 0) -- Legendary (Orange)
ITEM_QUALITY_COLORS[6] = CreateColor(0.9, 0.8, 0.5) -- Artifact / Vanity (Light Gold)
ITEM_QUALITY_COLORS[7] = CreateColor(0.9, 0.8, 0.5) -- Artifact / Vanity (Light Gold)
ITEM_QUALITY_COLORS[8] = CreateColor(0, 0.8, 1) -- Heirloom (Light Blue)
ITEM_QUALITY_COLORS[9] = CreateColor(0, 0.8, 1) -- Heirloom (Light Blue)

MYSTIC_ENCHANT_QUALITY_COLORS = {}
-- idk why but the old UIParent version included -1, 8 and 9
MYSTIC_ENCHANT_QUALITY_COLORS[-1] = CreateColor(1, 1, 1) -- invalid (White)
MYSTIC_ENCHANT_QUALITY_COLORS[0] = CreateColor(0.62, 0.62, 0.62) -- Poor (Grey)
MYSTIC_ENCHANT_QUALITY_COLORS[1] = CreateColor(1, 1, 1) -- Common (White)
MYSTIC_ENCHANT_QUALITY_COLORS[2] = CreateColor(0.12, 1, 0) -- Uncommon (Green)
MYSTIC_ENCHANT_QUALITY_COLORS[3] = CreateColor(0, 0.44, 0.87) -- Rare (Blue)
MYSTIC_ENCHANT_QUALITY_COLORS[4] = CreateColor(0.64, 0.21, 0.93) -- Epic (Purple)
MYSTIC_ENCHANT_QUALITY_COLORS[5] = CreateColor(1, 0.5, 0) -- Legendary (Orange)
MYSTIC_ENCHANT_QUALITY_COLORS[6] = CreateColor(0.9, 0.8, 0.5) -- Artifact / Vanity (Light Gold)
MYSTIC_ENCHANT_QUALITY_COLORS[7] = CreateColor(0.9, 0.8, 0.5) -- Artifact / Vanity (Light Gold)
MYSTIC_ENCHANT_QUALITY_COLORS[8] = CreateColor(0, 0.8, 1) -- Heirloom (Light Blue)
MYSTIC_ENCHANT_QUALITY_COLORS[9] = CreateColor(0, 0.8, 1) -- Heirloom (Light Blue)

ITEM_QUALITY_BORDER_ATLAS = {
	[0] = "item-border-grey",
	[1] = "item-border-white",
	[2] = "item-border-green",
	[3] = "item-border-blue",
	[4] = "item-border-purple",
	[5] = "item-border-orange",
	[6] = "item-border-artifact",
	[7] = "item-border-artifact",
	[8] = "item-border-heirloom",
	[9] = "item-border-heirloom",
}

ITEM_QUALITY_ROUND_BORDER_ATLAS = {
	[0] = "item-border-round-grey",
	[1] = "item-border-round-white",
	[2] = "item-border-round-green",
	[3] = "item-border-round-blue",
	[4] = "item-border-round-purple",
	[5] = "item-border-round-orange",
	[6] = "item-border-round-artifact",
	[7] = "item-border-round-artifact",
	[8] = "item-border-round-heirloom",
	[9] = "item-border-round-heirloom",
}

QUICKSLOT_QUALITY_BORDER_ATLAS = {
	[0] = "quickslot-border-grey",
	[1] = "quickslot-border-white",
	[2] = "quickslot-border-green",
	[3] = "quickslot-border-blue",
	[4] = "quickslot-border-purple",
	[5] = "quickslot-border-orange",
	[6] = "quickslot-border-artifact",
	[7] = "quickslot-border-artifact",
	[8] = "quickslot-border-heirloom",
	[9] = "quickslot-border-heirloom",
}

EXPANSION_COLORS = {}

EXPANSION_COLORS[0] = CreateColor(1, 0.9, 0.41) -- Classic
EXPANSION_COLORS[1] = CreateColor(0.6, 0.75, 0.26) -- TBC
EXPANSION_COLORS[2] = CreateColor(0.2, 0.39, 0.67) -- WoTLK
EXPANSION_COLORS[3] = CreateColor(0.83, 0.29, 0.11) -- CoA

ROLE_COLORS = {}
ROLE_COLORS["TANK"] = CreateColor(0.25, 0.54, 1)
ROLE_COLORS["DAMAGE"] = CreateColor(0.73, 0, 0)
ROLE_COLORS["HEALER"] = CreateColor(0, 0.73, 0.25)
ROLE_COLORS["SUPPORT"] = CreateColor(0, 0.73, 0.47)

ROLE_COLORS["DAMAGER"] = ROLE_COLORS["DAMAGE"]
ROLE_COLORS["Tank"] = ROLE_COLORS["TANK"]
ROLE_COLORS["MeleeDPS"] = ROLE_COLORS["DAMAGE"]
ROLE_COLORS["RangedDPS"] = ROLE_COLORS["DAMAGE"]
ROLE_COLORS["CasterDPS"] = ROLE_COLORS["DAMAGE"]
ROLE_COLORS["Healer"] = ROLE_COLORS["HEALER"]
ROLE_COLORS["Support"] = ROLE_COLORS["SUPPORT"]


ROLE_COLORS[Enum.LFGRoles.Tank] = ROLE_COLORS["TANK"]
ROLE_COLORS[Enum.LFGRoles.Damager] = ROLE_COLORS["DAMAGE"]
ROLE_COLORS[Enum.LFGRoles.Healer] = ROLE_COLORS["HEALER"]


--
-- Primary Stats
--
if IsCustomClass() then
	PRIMARY_STATS = {
		84864, -- Strength
		84865, -- Agility
		84866, -- Intellect
		84867, -- Spirit
		nil, -- Stamina (reserved)
		129243, -- Duality
	}
else
	PRIMARY_STATS = {
		84864, -- Strength
		84865, -- Agility
		84866, -- Intellect
		84867, -- Spirit
		nil, -- Stamina (reserved)
		129243, -- Duality
	}
end

STAT_COLORS = {
	Strength = CreateColor(0.78, 0.61, 0.43),
	Agility = CreateColor(1.00, 0.96, 0.41),
	Stamina = CreateColor(0.49, 0.78, 0.47),
	Duality = CreateColor(0.49, 0.78, 0.47),
	Intellect = CreateColor(0.4, 0.74, 0.82),
	Spirit = CreateColor(1, 1.00, 1),
}

STAT_COLORS[Enum.PrimaryStat.Strength] = STAT_COLORS.Strength
STAT_COLORS[Enum.PrimaryStat.Intellect] = STAT_COLORS.Intellect
STAT_COLORS[Enum.PrimaryStat.Stamina] = STAT_COLORS.Stamina
STAT_COLORS[Enum.PrimaryStat.Duality] = STAT_COLORS.Duality
STAT_COLORS[Enum.PrimaryStat.Agility] = STAT_COLORS.Agility
STAT_COLORS[Enum.PrimaryStat.Spirit] = STAT_COLORS.Spirit

FACTION_STANDING_COLORS = {
	[1] = CreateColor(0.8, 0.3, 0.22),
	[2] = CreateColor(0.8, 0.3, 0.22),
	[3] = CreateColor(0.75, 0.27, 0),
	[4] = CreateColor(0.9, 0.7, 0),
	[5] = CreateColor(0, 0.6, 0.1),
	[6] = CreateColor(0, 0.6, 0.1),
	[7] = CreateColor(0, 0.6, 0.1),
	[8] = CreateColor(0, 0.6, 0.1),
};

DIFFICULTY_COLORS = {
	[0] = CreateColor(0.5, 0.5, 0.5),
	[1] = CreateColor(0, 0.6, 0.1),
	[2] = CreateColor(0.4, 0.7, 0),
	[3] = CreateColor(0.9, 0.7, 0),
	[4] = CreateColor(0.75, 0.42, 0),
	[5] = CreateColor(0.8, 0.1, 0),
}

COMPLEXITY_COLORS = {
	["Normal"] = CreateColor(0.2, 1, 0.1),
	["Medium"] = CreateColor(0.7, 0.9, 0),
	["Hard"] = CreateColor(0.75, 0.27, 0),
	["VeryHard"] = CreateColor(0.8, 0.3, 0.22),
	["Impossible"] = CreateColor(0.8, 0.1, 0),
}

RAID_CLASS_COLORS = {
    ["HUNTER"]       = CreateColor(0.67, 0.83, 0.45),
    ["WARLOCK"]      = CreateColor(0.58, 0.51, 0.79),
    ["PRIEST"]       = CreateColor(1.0, 1.0, 1.0),
    ["PALADIN"]      = CreateColor(0.96, 0.55, 0.73),
    ["MAGE"]         = CreateColor(0.41, 0.8, 0.94),
    ["ROGUE"]        = CreateColor(1.0, 0.96, 0.41),
    ["DRUID"]        = CreateColor(1.0, 0.49, 0.04),
    ["SHAMAN"]       = CreateColor(0.0, 0.44, 0.87),
    ["WARRIOR"]      = CreateColor(0.78, 0.61, 0.43),
    ["DEATHKNIGHT"]  = CreateColor(0.77, 0.12, 0.23),
    ["HERO"]         = CreateColor(1, 0.84, 0.14),
    ["BARBARIAN"]    = CreateColor(0.54, 0.20, 0.01),
    ["WITCHDOCTOR"]  = CreateColor(0.96, 0.00, 1.00),
    ["DEMONHUNTER"]  = CreateColor(0.46, 0.98, 0.00),
    ["WITCHHUNTER"]  = CreateColor(0.33, 0.20, 0.81),
    ["STORMBRINGER"] = CreateColor(0.00, 0.49, 0.93),
    ["FLESHWARDEN"]  = CreateColor(0.99, 0.00, 0.02),
    ["GUARDIAN"]     = CreateColor(0.61, 0.58, 0.51),
    ["MONK"]         = CreateColor(1.00, 0.98, 0.70),
    ["SONOFARUGAL"]  = CreateColor(0.64, 0.00, 0.00),
    ["RANGER"]       = CreateColor(0.75, 0.94, 0.42),
    ["PROPHET"]      = CreateColor(0.42, 0.65, 0.00),
    ["PYROMANCER"]   = CreateColor(1.00, 0.38, 0.07),
    ["CULTIST"]      = CreateColor(0.61, 0.27, 0.95),
    ["NECROMANCER"]  = CreateColor(0.27, 0.86, 0.61),
    ["SUNCLERIC"]    = CreateColor(1.00, 0.70, 0.25),
    ["TINKER"]       = CreateColor(0.85, 0.85, 0.85),
    ["REAPER"]       = CreateColor(0.04, 0.53, 0.42),
    ["WILDWALKER"]   = CreateColor(0.89, 0.55, 0.35),
    ["STARCALLER"]   = CreateColor(0.56, 1.00, 1.00),
    ["SPIRITMAGE"]   = CreateColor(0.25, 0.78, 0.92),
    ["CHRONOMANCER"] = CreateColor(1.00, 0.93, 0.29) 
};

CANNOT_USE_ITEM_COLOR = CreateColor(0.9, 0, 0)

LOCALIZED_CLASS_NAMES_MALE = {};
LOCALIZED_CLASS_NAMES_FEMALE = {};
FillLocalizedClassList(LOCALIZED_CLASS_NAMES_MALE, false);
FillLocalizedClassList(LOCALIZED_CLASS_NAMES_FEMALE, true);

for class in pairs(LOCALIZED_CLASS_NAMES_MALE) do
    if not RAID_CLASS_COLORS[class] then
        LOCALIZED_CLASS_NAMES_MALE[class] = nil
    end
end

for class in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
    if not RAID_CLASS_COLORS[class] then
        LOCALIZED_CLASS_NAMES_MALE[class] = nil
    end
end

UNLOCALIZED_CLASS_NAMES = tinvert(LOCALIZED_CLASS_NAMES_MALE)

-- Tooltip Globals
DEFAULT_TOOLTIP_POSITION = -13;

-- overwrite GetItemQualityColor
_GetItemQualityColor = _GetItemQualityColor or GetItemQualityColor
---Returns R G B color codes and UI escape color hex without the leading |c
---@param index
function GetItemQualityColor(index)
	local quality = tonumber(index)
	if quality then
		local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[1]
		return color.r, color.g, color.b, color.hex
	else
		return _GetItemQualityColor(index)
	end
end

-- Returns the ITEM_QUALITY_DESC for the given index, wrapped in it's ITEM_QUALITY_COLORS color code
function GetColoredItemQualityText(index)
	index = tonumber(index)
	assert(type(index) == "number", "Usage: GetColoredItemQuality(number)")

	local color = ITEM_QUALITY_COLORS[index] or ITEM_QUALITY_COLORS[1]
	local text = _G["ITEM_QUALITY" .. index .. "_DESC"] or index
	return color:WrapText(text)
end

GAME_MODE_COLOR = {
	None             = CreateColor(1, 1, 1),
	Random           = CreateColor(1, 1, 1),
	Ironman          = CreateColor(0.78, 0.61, 0.43), -- Warrior
	Survivalist      = CreateColor(0.67, 0.83, 0.45), -- Hunter
	Draft            = CreateColor(0.12, 1, 0), -- Uncommon Color
	Resolute         = CreateColor(0.1647, 0.6353, 1.0), -- Kyrian Blue
	WildCard         = CreateColor(0.12, 1, 0), -- Uncommon Color,
	Felforged        = CreateColor(0.49, 0.84, 0.12), -- #7fd81e Legion-y color
	Nightmare        = CreateColor(0.53, 0.53, 0.93), -- Warlock
	BuildDraft       = CreateColor(0, 0.8, 1), -- Heirloom Color
	Crusader         = CreateColor(0.95, 0.90, 0.60), -- #F2E699 Holy Power
	FreepickRarities = CreateColor(0.12, 1, 0) -- Uncommon Color
}

CLASS_ICON_TCOORDS = {
	["WARRIOR"]      = "",
	["MAGE"]         = "",
	["ROGUE"]        = "",
	["DRUID"]        = "",
	["HUNTER"]       = "",
	["SHAMAN"]       = "",
	["PRIEST"]       = "",
	["WARLOCK"]      = "",
	["PALADIN"]      = "",
	["DEATHKNIGHT"]  = "",
	["HERO"]         = "",
	["BARBARIAN"]    = "",
	["WITCHDOCTOR"]  = "",
	["DEMONHUNTER"]  = "",
	["WITCHHUNTER"]  = "",
	["STORMBRINGER"] = "",
	["FLESHWARDEN"]  = "",
	["GUARDIAN"]     = "",
	["MONK"]         = "",
	["SONOFARUGAL"]  = "",
	["RANGER"]       = "",
	["PROPHET"]      = "",
	["CHRONOMANCER"] = "",
	["PYROMANCER"]   = "",
	["CULTIST"]      = "",
	["NECROMANCER"]  = "",
	["SUNCLERIC"]    = "",
	["TINKER"]       = "",
	["REAPER"]       = "",
	["WILDWALKER"]   = "",
	["STARCALLER"]   = "",
	["SPIRITMAGE"]   = "",
};

for class in pairs(CLASS_ICON_TCOORDS) do
	local atlas = "class-"..class:lower()
	CLASS_ICON_TCOORDS[class] = { AtlasUtil:GetCoords(atlas) }
end

CLASS_ICON_TCOORDS_ROUND = {
	["WARRIOR"]      = "",
	["MAGE"]         = "",
	["ROGUE"]        = "",
	["DRUID"]        = "",
	["HUNTER"]       = "",
	["SHAMAN"]       = "",
	["PRIEST"]       = "",
	["WARLOCK"]      = "",
	["PALADIN"]      = "",
	["DEATHKNIGHT"]  = "",
	["HERO"]         = "",
	["BARBARIAN"]    = "",
	["WITCHDOCTOR"]  = "",
	["DEMONHUNTER"]  = "",
	["WITCHHUNTER"]  = "",
	["STORMBRINGER"] = "",
	["FLESHWARDEN"]  = "",
	["GUARDIAN"]     = "",
	["MONK"]         = "",
	["SONOFARUGAL"]  = "",
	["RANGER"]       = "",
	["PROPHET"]      = "",
	["CHRONOMANCER"] = "",
	["PYROMANCER"]   = "",
	["CULTIST"]      = "",
	["NECROMANCER"]  = "",
	["SUNCLERIC"]    = "",
	["TINKER"]       = "",
	["REAPER"]       = "",
	["WILDWALKER"]   = "",
	["STARCALLER"]   = "",
	["SPIRITMAGE"]   = "",
}

for class in pairs(CLASS_ICON_TCOORDS_ROUND) do
	local atlas = "class-round-"..class:lower()
	CLASS_ICON_TCOORDS_ROUND[class] = { AtlasUtil:GetCoords(atlas) }
end

CHAR_CREATE_CAMERA_ZOOM_OUTS = {
	["BloodElf"] = {
		-5.05955,
		4.270,
		0.45446,
	},
	["Orc"] = {
		4.8, 
		0.206, 
		0.5288,
	},
	["Scourge"] = {
	 	4, 
		-0.05, 
		0.28
	},
	["Tauren"] = {
		4.912, 
		-0.004, 
		0.37,
	},
	["Draenei"] = {
		6.921, 
		1.128, 
		0.461
	},
	["Human"] = {
		-180.38, 
		-67.15,
		-1.87,
	},
	["NightElf"] = {
		1.0939, 
		-0.26, 
		2.23
	},
}

CHAR_CREATE_PASSIVES = {
	["ORC"] = {33697, -- orc 1
		20573, -- orc 2
		20575, -- orc 3
		20574, -- orc 4
	},

	["TAUREN"] = {20549, -- tauren 1
		20550, -- tauren 2
		20552, -- tauren 3
		20551, -- tauren 4
	},

	["SCOURGE"] = {7744, -- undead 1
		20577, -- undead 2
		5227, -- undead 3
		20579, -- undead 4
	},

	["TROLL"] = {26297, -- troll 1
		20555, -- troll 2
		20557, -- troll 3
		26290, -- troll 4
		58943, -- troll 5
	},

	["BLOODELF"] = {28877, -- be 1
		28730, -- be 2
		28730, -- be 3
		822, -- be 4
	},

	["HUMAN"] = {58985, -- human 1
		20598, -- human 2
		20599, -- human 3
		20597, -- human 4
		59752, -- human 5
	},

	["DWARF"] = {20594, -- dwarf 1
		20595, -- dwarf 2
		20596, -- dwarf 3
		2481, -- dwarf 4
		59224, -- dwarf 5
	},

	["NIGHTELF"] = {58984, -- ne 1
		20582, -- ne 2
		20585, -- ne 4
		20583, -- ne 5
	},

	["GNOME"] = {20589, -- gn 1
		20591, -- gn 2
		20592, -- gn 3
		20593, -- gn 4
	},

	["DRAENEI"] = {28875, -- dr 1
		59542, -- dr 2
		28878, -- dr 3
		59221, -- dr 4
	},
}

RACE_ICON_TCOORDS = {
	["HUMAN_MALE"]      = { 0, 0.125, 0, 0.25 },
	["DWARF_MALE"]      = { 0.125, 0.25, 0, 0.25 },
	["GNOME_MALE"]      = { 0.25, 0.375, 0, 0.25 },
	["NIGHTELF_MALE"]   = { 0.375, 0.5, 0, 0.25 },

	["TAUREN_MALE"]     = { 0, 0.125, 0.25, 0.5 },
	["SCOURGE_MALE"]    = { 0.125, 0.25, 0.25, 0.5 },
	["TROLL_MALE"]      = { 0.25, 0.375, 0.25, 0.5 },
	["ORC_MALE"]        = { 0.375, 0.5, 0.25, 0.5 },

	["HUMAN_FEMALE"]    = { 0, 0.125, 0.5, 0.75 },
	["DWARF_FEMALE"]    = { 0.125, 0.25, 0.5, 0.75 },
	["GNOME_FEMALE"]    = { 0.25, 0.375, 0.5, 0.75 },
	["NIGHTELF_FEMALE"] = { 0.375, 0.5, 0.5, 0.75 },

	["TAUREN_FEMALE"]   = { 0, 0.125, 0.75, 1.0 },
	["SCOURGE_FEMALE"]  = { 0.125, 0.25, 0.75, 1.0 },
	["TROLL_FEMALE"]    = { 0.25, 0.375, 0.75, 1.0 },
	["ORC_FEMALE"]      = { 0.375, 0.5, 0.75, 1.0 },

	["BLOODELF_MALE"]   = { 0.5, 0.625, 0.25, 0.5 },
	["BLOODELF_FEMALE"] = { 0.5, 0.625, 0.75, 1.0 },

	["DRAENEI_MALE"]    = { 0.5, 0.625, 0, 0.25 },
	["DRAENEI_FEMALE"]  = { 0.5, 0.625, 0.5, 0.75 },
}

LOCALIZED_CLASS_SPEC_NAMES = {
	["DEATHKNIGHT"]  = {
		["BLOOD"]  = "Blood",
		["FROST"]  = "Frost",
		["UNHOLY"] = "Unholy",
	},
	["WARRIOR"]      = {
		["ARMS"]       = "Arms",
		["FURY"]       = "Fury",
		["PROTECTION"] = "Protection"
	},
	["DRUID"]        = {
		["BALANCE"]     = "Balance",
		["FERAL"]       = "Feral",
		["RESTORATION"] = "Restoration"
	},
	["PRIEST"]       = {
		["DISCIPLINE"] = "Discipline",
		["HOLY"]       = "Holy",
		["SHADOW"]     = "Shadow"
	},
	["MAGE"]         = {
		["ARCANE"] = "Arcane",
		["FIRE"]   = "Fire",
		["FROST"]  = "Frost"
	},
	["HUNTER"]       = {
		["BEASTMASTERY"] = "Beast Mastery",
		["MARKSMANSHIP"] = "Marksmanship",
		["SURVIVAL"]     = "Survival"
	},
	["PALADIN"]      = {
		["HOLY"]        = "Holy",
		["PROTECTION"]  = "Protection",
		["RETRIBUTION"] = "Retribution"
	},
	["ROGUE"]        = {
		["ASSASSINATION"] = "Assassination",
		["COMBAT"]        = "Combat",
		["SUBTLETY"]      = "Subtlety"
	},
	["WARLOCK"]      = {
		["AFFLICTION"]  = "Affliction",
		["DEMONOLOGY"]  = "Demonology",
		["DESTRUCTION"] = "Destruction",
	},
	["SHAMAN"]       = {
		["ELEMENTAL"]   = "Elemental",
		["ENHANCEMENT"] = "Enhancement",
		["RESTORATION"] = "Restoration"
	},
	["BARBARIAN"]    = {
		["BRUTALITY"] = "Brutality",
		["TACTICS"]   = "Tactics",
		["ANCESTRY"]  = "Ancestry",
	},
	["WITCHDOCTOR"]  = {
		["VOODOO"]        = "Voodoo",
		["BREWING"]       = "Brewing",
		["SHADOWHUNTING"] = "Shadowhunting",
	},
	["DEMONHUNTER"]  = {
		["SLAYING"]    = "Slaying",
		["DEMONOLOGY"] = "Demonology",
		["FELBLOOD"]   = "Felblood",
	},
	["WITCHHUNTER"]  = {
		["INQUISITION"] = "Inquisition",
		["DARKNESS"]    = "Darkness",
		["BOLTSLINGER"] = "Boltslinger",
	},
	["STORMBRINGER"] = {
		["LIGHTNING"] = "Lightning",
		["GIFTS"]     = "Gifts",
		["WIND"]      = "Wind",
	},
	["FLESHWARDEN"]  = {
		["HELLFIRE"] = "Hellfire",
		["WAR"]      = "War",
		["DEFIANCE"] = "Defiance",
	},
	["GUARDIAN"]     = {
		["GLADIATOR"]   = "Gladiator",
		["PROTECTION"]  = "Protection",
		["INSPIRATION"] = "Inspiration",
	},
	["MONK"]         = {
		["FIGHTING"]   = "Fighting",
		["RUNES"]      = "Runes",
		["DISCIPLINE"] = "Discipline",
	},
	["SONOFARUGAL"]  = {
		["BLOOD"]      = "Blood",
		["FEROCITY"]   = "Ferocity",
		["PACKLEADER"] = "Packleader",
	},
	["RANGER"]       = {
		["DUELING"]  = "Dueling",
		["ARCHERY"]  = "Archery",
		["SURVIVAL"] = "Survival",
	},
	["PROPHET"]      = {
		["STALKING"]  = "Stalking",
		["FORTITUDE"] = "Fortitude",
		["VENOM"]     = "Venom",
	},
	["PYROMANCER"]   = {
		["DESTRUCTION"]  = "Destruction",
		["INCINERATION"] = "Incineration",
		["DRACONIC"]     = "Draconic",
	},
	["CULTIST"]      = {
		["CORRUPTION"] = "Corruption",
		["GODBLADE"]   = "Godblade",
		["INFLUENCE"]  = "Influence",
	},
	["NECROMANCER"]  = {
		["RIME"]      = "Rime",
		["ANIMATION"] = "Animation",
		["DEATH"]     = "Death",
	},
	["SUNCLERIC"]    = {
		["BLESSINGS"] = "Blessings",
		["SERAPHIM"]  = "Seraphim",
		["PIETY"]     = "Piety",
	},
	["TINKER"]       = {
		["INVENTION"] = "Invention",
		["MECHANICS"] = "Mechanics",
		["FIREARMS"]  = "Firearms",
	},
	["REAPER"]       = {
		["SOUL"]       = "Soul",
		["REAPING"]    = "Reaping",
		["DOMINATION"] = "Domination",
	},
	["WILDWALKER"]   = {
		["GEOMANCY"] = "Geomancy",
		["PRIMAL"]   = "Primal",
		["LIFE"]     = "Life",
	},
	["STARCALLER"]   = {
		["ASTRALWARFARE"] = "Astral Warfare",
		["MOONBOW"]       = "Moonbow",
		["TIDES"]         = "Tides",
	},
	["SPIRITMAGE"]   = {
		["RUNIC"]     = "Runic",
		["ARCANE"]    = "Arcane",
		["RIFTBLADE"] = "Riftblade",
	},
	["CHRONOMANCER"] = {
		["DUALITY"]      = "Duality",
		["TIME"]         = "Time",
		["DISPLACEMENT"] = "Displacement",
	},
}

SPEC_ICONS = {
	["BRUTALITY"]     = "Interface\\Icons\\Ability_Warrior_BloodFrenzy",
	["TACTICS"]       = "Interface\\Icons\\Achievement_Arena_5v5_5",
	["ANCESTRY"]      = "Interface\\Icons\\Achievement_Dungeon_UtgardeKeep_Normal",
	["VOODOO"]        = "Interface\\Icons\\INV_Misc_Idol_02",
	["BREWING"]       = "Interface\\Icons\\INV_Misc_Cauldron_Nature",
	["SHADOWHUNTING"] = "Interface\\Icons\\Ability_Hunter_SurvivalInstincts",
	["SLAYING"]       = "Interface\\Icons\\INV_Weapon_Glave_01",
	["FELBLOOD"]      = "Interface\\Icons\\Spell_Shadow_FingerOfDeath",
	["DEMONOLOGY"]    = "Interface\\Icons\\Ability_Warlock_DemonicPower",
	["BOLTSLINGER"]   = "Interface\\Icons\\_D3preparation",
	["DARKNESS"]      = "Interface\\Icons\\Ability_Warlock_ImprovedSoulLeech",
	["INQUISITION"]   = "Interface\\Icons\\Ability_Rogue_StayofExecution",
	["LIGHTNING"]     = "Interface\\Icons\\ability_vehicle_electrocharge",
	["WIND"]          = "Interface\\Icons\\Spell_Nature_InvisibilityTotem",
	["GIFTS"]         = "Interface\\Icons\\Achievement_Boss_Thorim",
	["WAR"]           = "Interface\\Icons\\INV_MISC_HOOK_01",
	["HELLFIRE"]      = "Interface\\Icons\\Spell_Shadow_ShadowandFlame",
	["DEFIANCE"]      = "Interface\\Icons\\INV_Belt_18",
	["PROTECTION"]    = "Interface\\Icons\\Ability_Warrior_SwordandBoard",
	["INSPIRATION"]   = "Interface\\Icons\\Achievement_BG_winWSG_3-0",
	["GLADIATOR"]     = "Interface\\Icons\\Achievement_BG_KillFlagCarriers_grabFlag_CapIt",
	["FIGHTING"]      = "Interface\\Icons\\_D3deadlyreach",
	["DISCIPLINE"]    = "Interface\\Icons\\_D3blindingflash",
	["RUNES"]         = "Interface\\Icons\\Ability_Paladin_BlessedHands",
	["BLOOD"]         = "Interface\\Icons\\Spell_Shadow_LifeDrain",
	["FEROCITY"]      = "Interface\\Icons\\Spell_DeathKnight_Gnaw_Ghoul",
	["PACKLEADER"]    = "Interface\\Icons\\achievement_dungeon_jeshowlis",
	["ARCHERY"]       = "Interface\\Icons\\Ability_Hunter_LongShots",
	["DUELING"]       = "Interface\\Icons\\ability_rogue_rollthebones02",
	["SURVIVAL"]      = "Interface\\Icons\\INV_Misc_Map02",
	["DUALITY"]       = "Interface\\Icons\\inv_enchant_philostone_lv2",
	["TIME"]          = "Interface\\Icons\\inv_wand_1h_pvp400_c_01",
	["DISPLACEMENT"]  = "Interface\\Icons\\_AuraCloak_Ice",
	["DEATH"]         = "Interface\\Icons\\achievement_dungeon_naxxramas_25man",
	["RIME"]          = "Interface\\Icons\\Achievement_Boss_Amnennar_the_Coldbringer",
	["ANIMATION"]     = "Interface\\Icons\\_D3wallofzombies",
	["INCINERATION"]  = "Interface\\Icons\\Ability_Warlock_Backdraft",
	["DESTRUCTION"]   = "Interface\\Icons\\Ability_Mage_FieryPayback",
	["DRACONIC"]      = "Interface\\Icons\\INV_Weapon_Hand_06",
	["GODBLADE"]      = "Interface\\Icons\\INV_Sword_61",
	["CORRUPTION"]    = "Interface\\Icons\\Achievement_Boss_CThun",
	["INFLUENCE"]     = "Interface\\Icons\\spell_shadow_rune",
	["ASTRALWARFARE"] = "Interface\\Icons\\ability_hunter_carve",
	["TIDES"]         = "Interface\\Icons\\Spell_Frost_ManaRecharge",
	["MOONBOW"]       = "Interface\\Icons\\_Diablo3_ArrowRain_Mage",
	["PIETY"]         = "Interface\\Icons\\ability_racial_finalverdict",
	["BLESSINGS"]     = "Interface\\Icons\\Ability_Paladin_SacredCleansing",
	["SERAPHIM"]      = "Interface\\Icons\\Spell_Holy_Crusade",
	["FIREARMS"]      = "Interface\\Icons\\INV_Musket_04",
	["INVENTION"]     = "Interface\\Icons\\INV_Gizmo_RocketBootExtreme",
	["MECHANICS"]     = "Interface\\Icons\\INV_Misc_EngGizmos_06",
	["VENOM"]         = "Interface\\Icons\\_LiquidStone_Poison",
	["STALKING"]      = "Interface\\Icons\\inv_pet_spiderdemon",
	["FORTITUDE"]     = "Interface\\Icons\\ability_mount_hordescorpionamber",
	["REAPING"]       = "Interface\\Icons\\ability_rogue_sealfate",
	["SOUL"]          = "Interface\\Icons\\inv_artifact_thalkielsdiscord",
	["DOMINATION"]    = "Interface\\Icons\\ability_touchofanimus",
	["PRIMAL"]        = "Interface\\Icons\\_BearAttack_BrownFire",
	["GEOMANCY"]      = "Interface\\Icons\\inv_elementalearth2",
	["LIFE"]          = "Interface\\Icons\\Spell_Shaman_BlessingOfEternals",
	["ARCANE"]        = "Interface\\Icons\\_D3arcanetorrent",
	["RUNIC"]         = "Interface\\Icons\\70_inscription_vantus_rune_azure",
	["RIFTBLADE"]     = "Interface\\Icons\\INV_Weapon_Shortblade_79",
}

CLASS_PRIMARY_STAT = {
	["BARBARIAN"]    = Enum.PrimaryStat.Agility,
	["WITCHDOCTOR"]  = Enum.PrimaryStat.Intellect,
	["DEMONHUNTER"]  = Enum.PrimaryStat.Agility,
	["WITCHHUNTER"]  = Enum.PrimaryStat.Agility,
	["STORMBRINGER"] = Enum.PrimaryStat.Intellect,
	["FLESHWARDEN"]  = Enum.PrimaryStat.Strength, -- Knight of Xoroth
	["GUARDIAN"]     = Enum.PrimaryStat.Strength,
	["MONK"]         = Enum.PrimaryStat.Agility,
	["SONOFARUGAL"]  = Enum.PrimaryStat.Agility,
	["RANGER"]       = Enum.PrimaryStat.Agility,
	["PROPHET"]      = Enum.PrimaryStat.Intellect, -- Venomancer
	["PYROMANCER"]   = Enum.PrimaryStat.Intellect,
	["CULTIST"]      = Enum.PrimaryStat.Strength,
	["NECROMANCER"]  = Enum.PrimaryStat.Intellect,
	["SUNCLERIC"]    = Enum.PrimaryStat.Intellect,
	["TINKER"]       = Enum.PrimaryStat.Agility,
	["REAPER"]       = Enum.PrimaryStat.Agility,
	["WILDWALKER"]   = Enum.PrimaryStat.Agility, -- Primalist
	["STARCALLER"]   = Enum.PrimaryStat.Intellect,
	["SPIRITMAGE"]   = Enum.PrimaryStat.Intellect, -- Runemaster
	["CHRONOMANCER"] = Enum.PrimaryStat.Spirit,
}

SPEC_PRIMARY_STAT = {
	["BRUTALITY"]     = Enum.PrimaryStat.Agility, -- Barbarian
	["TACTICS"]       = Enum.PrimaryStat.Agilitiy, -- Barbarian
	["ANCESTRY"]      = Enum.PrimaryStat.Agility, -- Barbarian
	["VOODOO"]        = Enum.PrimaryStat.Intellect, -- Witch Doctor
	["BREWING"]       = Enum.PrimaryStat.Spirit, -- Witch Doctor
	["SHADOWHUNTING"] = Enum.PrimaryStat.Agility, -- Witch Doctor
	["SLAYING"]       = Enum.PrimaryStat.Agility, -- Demon Hunter
	["FELBLOOD"]      = Enum.PrimaryStat.Intellect, -- Demon Hunter
	["DEMONOLOGY"]    = Enum.PrimaryStat.Agility, -- Demon Hunter
	["BOLTSLINGER"]   = Enum.PrimaryStat.Agility, -- Witch Hunter
	["DARKNESS"]      = Enum.PrimaryStat.Agility, -- Witch Hunter
	["INQUISITION"]   = Enum.PrimaryStat.Agility, -- Witch Hunter
	["LIGHTNING"]     = Enum.PrimaryStat.Intellect, -- Stormbringer
	["WIND"]          = Enum.PrimaryStat.Intellect, -- Stormbringer
	["GIFTS"]         = Enum.PrimaryStat.Intellect, -- Stormbringer
	["WAR"]           = Enum.PrimaryStat.Strength, -- Knight of Xoroth
	["HELLFIRE"]      = Enum.PrimaryStat.Intellect, -- Knight of Xoroth
	["DEFIANCE"]      = Enum.PrimaryStat.Strength, -- Knight of Xoroth
	["PROTECTION"]    = Enum.PrimaryStat.Strength, -- Guardian
	["INSPIRATION"]   = Enum.PrimaryStat.Spirit, -- Guardian
	["GLADIATOR"]     = Enum.PrimaryStat.Strength, -- Guardian
	["FIGHTING"]      = Enum.PrimaryStat.Agility, -- Monk
	["DISCIPLINE"]    = Enum.PrimaryStat.Agility, -- Monk
	["RUNES"]         = Enum.PrimaryStat.Strength, -- Monk
	["BLOOD"]         = Enum.PrimaryStat.Intellect, -- Son of Arugal
	["FEROCITY"]      = Enum.PrimaryStat.Agility, -- Son of Arugal
	["PACKLEADER"]    = Enum.PrimaryStat.Agility, -- Son of Arugal
	["ARCHERY"]       = Enum.PrimaryStat.Agility, -- Ranger
	["DUELING"]       = Enum.PrimaryStat.Agility, -- Ranger
	["SURVIVAL"]      = Enum.PrimaryStat.Agility, -- Ranger
	["DUALITY"]       = Enum.PrimaryStat.Spirit, -- Chronomancer
	["TIME"]          = Enum.PrimaryStat.Spirit, -- Chronomancer
	["DISPLACEMENT"]  = Enum.PrimaryStat.Spirit, -- Chronomancer
	["DEATH"]         = Enum.PrimaryStat.Intellect, -- Necromancer
	["RIME"]          = Enum.PrimaryStat.Intellect, -- Necromancer
	["ANIMATION"]     = Enum.PrimaryStat.Intellect, -- Necromancer
	["INCINERATION"]  = Enum.PrimaryStat.Intellect, -- Pyromancer
	["DESTRUCTION"]   = Enum.PrimaryStat.Intellect, -- Pyromancer
	["DRACONIC"]      = Enum.PrimaryStat.Intellect, -- Pyromancer
	["GODBLADE"]      = Enum.PrimaryStat.Strength, -- Cultist
	["CORRUPTION"]    = Enum.PrimaryStat.Intellect, -- Cultist
	["INFLUENCE"]     = Enum.PrimaryStat.Spirit, -- Cultist
	["ASTRALWARFARE"] = Enum.PrimaryStat.Strength, -- Starcaller
	["TIDES"]         = Enum.PrimaryStat.Spirit, -- Starcaller
	["MOONBOW"]       = Enum.PrimaryStat.Intellect, -- Starcaller
	["PIETY"]         = Enum.PrimaryStat.Intellect, -- Sun Cleric
	["BLESSINGS"]     = Enum.PrimaryStat.Spirit, -- Sun Cleric
	["SERAPHIM"]      = Enum.PrimaryStat.Strength, -- Sun Cleric
	["FIREARMS"]      = Enum.PrimaryStat.Agility, -- Tinker
	["INVENTION"]     = Enum.PrimaryStat.Spirit, -- Tinker
	["MECHANICS"]     = Enum.PrimaryStat.Agility, -- Tinker
	["VENOM"]         = Enum.PrimaryStat.Spirit, -- Venomancer
	["STALKING"]      = Enum.PrimaryStat.Intellect, -- Venomancer
	["FORTITUDE"]     = Enum.PrimaryStat.Intellect, -- Venomancer
	["REAPING"]       = Enum.PrimaryStat.Agility, -- Reaper
	["SOUL"]          = Enum.PrimaryStat.Intellect, -- Reaper
	["DOMINATION"]    = Enum.PrimaryStat.Strength, -- Reaper
	["PRIMAL"]        = Enum.PrimaryStat.Agility, -- Primalist
	["GEOMANCY"]      = Enum.PrimaryStat.Spirit, -- Primalist
	["LIFE"]          = Enum.PrimaryStat.Agility, -- Primalist
	["ARCANE"]        = Enum.PrimaryStat.Intellect, -- Runemaster
	["RUNIC"]         = Enum.PrimaryStat.Spirit, -- Runemaster
	["RIFTBLADE"]     = Enum.PrimaryStat.Intellect, -- Runemaster
}

ROLE_TEXT = {
	[Enum.ClassRole.MeleeDPS] = MELEE_DAMAGER,
	[Enum.ClassRole.RangedDPS] = RANGED_DAMAGER,
	[Enum.ClassRole.CasterDPS] = CASTER_DAMAGER,
	[Enum.ClassRole.Tank] = TANK,
	[Enum.ClassRole.Healer] = HEALER,
	[Enum.ClassRole.Support] = SUPPORT,
}

ROLE_TEXT_SHORT = {
	[Enum.ClassRole.MeleeDPS] = MELEE_DAMAGER_SHORT,
	[Enum.ClassRole.RangedDPS] = RANGED_DAMAGER_SHORT,
	[Enum.ClassRole.CasterDPS] = CASTER_DAMAGER_SHORT,
	[Enum.ClassRole.Tank] = TANK_SHORT,
	[Enum.ClassRole.Healer] = HEALER_SHORT,
	[Enum.ClassRole.Support] = SUPPORT_SHORT,
}

ROLE_ATLAS = {
	[Enum.ClassRole.MeleeDPS] = "ui-lfg-roleicon-dps",
	[Enum.ClassRole.RangedDPS] = "ui-lfg-roleicon-rangeddps",
	[Enum.ClassRole.CasterDPS] = "ui-lfg-roleicon-casterdps",
	[Enum.ClassRole.Tank] = "ui-lfg-roleicon-tank",
	[Enum.ClassRole.Healer] = "ui-lfg-roleicon-healer",
	[Enum.ClassRole.Support] = "ui-lfg-roleicon-generic",
	MELEE_DAMAGER = "ui-lfg-roleicon-dps",
	RANGED_DAMAGER = "ui-lfg-roleicon-rangeddps",
	CASTER_DAMAGER = "ui-lfg-roleicon-casterdps",
	DAMAGER = "ui-lfg-roleicon-dps",
	TANK = "ui-lfg-roleicon-tank",
	HEALER = "ui-lfg-roleicon-healer",
	SUPPORT = "ui-lfg-roleicon-generic",
	LEADER = "ui-lfg-roleicon-leader",
	GENERIC = "ui-lfg-roleicon-generic",
}

ROLE_TEXT_WITH_ICON = {
	MELEE_DAMAGER = "|Tinterface\\lfgframe\\uilfgprompts:20:20:0:0:2048:2048:1947:2008:259:320|t |cffba0000"..MELEE_DAMAGER.."|r",
	RANGED_DAMAGER = "|Tinterface\\lfgframe\\uilfgprompts:20:20:0:0:2048:2048:0:61:1805:1866|t |cffba0000"..RANGED_DAMAGER.."|r",
	CASTER_DAMAGER = "|Tinterface\\lfgframe\\uilfgprompts:20:20:0:0:2082:2082:1980:2041:524:585|t |cffba0000"..CASTER_DAMAGER.."|r",
	DAMAGER = "|Tinterface\\lfgframe\\uilfgprompts:20:20:0:0:2048:2048:0:61:1805:1866|t |cffba0000"..DAMAGER.."|r",
	TANK = "|Tinterface\\lfgframe\\uilfgprompts:20:20:0:0:2048:2047:0:61:1867:1928|t |cff408aff"..TANK.."|r",
	HEALER = "|Tinterface\\lfgframe\\uilfgprompts:20:20:0:0:2048:2048:1947:2008:385:446|t |cff00ba40"..HEALER.."|r",
	SUPPORT = "|Tinterface\\lfgframe\\uilfgprompts:20:20:0:0:2048:2048:1947:2008:322:383|t |cff00ba79"..SUPPORT.."|r",
}

ARMOR_TYPE_ATLAS = {
	Plate = "armor-proficiency-plate",
	Mail = "armor-proficiency-mail",
	Leather = "armor-proficiency-leather",
	Cloth = "armor-proficiency-cloth",
	[Enum.ClassArmorType.Plate] = "armor-proficiency-plate",
	[Enum.ClassArmorType.Mail] = "armor-proficiency-mail",
	[Enum.ClassArmorType.Leather] = "armor-proficiency-leather",
	[Enum.ClassArmorType.Cloth] = "armor-proficiency-cloth",
}

ARMOR_TYPE_NAME = {
	Plate = ARMOR_TYPE_PLATE,
	Mail = ARMOR_TYPE_MAIL,
	Leather = ARMOR_TYPE_LEATHER,
	Cloth = ARMOR_TYPE_CLOTH,
	[Enum.ClassArmorType.Plate] = ARMOR_TYPE_PLATE,
	[Enum.ClassArmorType.Mail] = ARMOR_TYPE_MAIL,
	[Enum.ClassArmorType.Leather] = ARMOR_TYPE_LEATHER,
	[Enum.ClassArmorType.Cloth] = ARMOR_TYPE_CLOTH,
}

ARMOR_TYPE_WITH_ICON = {
	PLATE = "|TInterface\\ContainerFrame\\ArmorProficiencyTypes:20:20:0:0:128:128:0:60:1:61|t " .. ARMOR_TYPE_PLATE,
	MAIL = "|TInterface\\ContainerFrame\\ArmorProficiencyTypes:20:20:0:0:128:128:68:128:1:61|t " .. ARMOR_TYPE_MAIL,
	LEATHER = "|TInterface\\ContainerFrame\\ArmorProficiencyTypes:20:20:0:0:128:128:0:60:68:128|t " .. ARMOR_TYPE_LEATHER,
	CLOTH = "|TInterface\\ContainerFrame\\ArmorProficiencyTypes:20:20:0:0:128:128:64:124:68:128|t " .. ARMOR_TYPE_CLOTH,
}

PRIMARY_STAT_ATLAS = {
	Strength = "primary-stat-circle-strength",
	Agility = "primary-stat-circle-agility",
	Stamina = "primary-stat-circle-stamina",
	Duality = "primary-stat-circle-stamina",
	Intellect = "primary-stat-circle-intellect",
	Spirit = "primary-stat-circle-spirit",
}

PRIMARY_STAT_ATLAS[Enum.PrimaryStat.Strength] = PRIMARY_STAT_ATLAS.Strength
PRIMARY_STAT_ATLAS[Enum.PrimaryStat.Agility] = PRIMARY_STAT_ATLAS.Agility
PRIMARY_STAT_ATLAS[Enum.PrimaryStat.Stamina] = PRIMARY_STAT_ATLAS.Stamina
PRIMARY_STAT_ATLAS[Enum.PrimaryStat.Duality] = PRIMARY_STAT_ATLAS.Duality
PRIMARY_STAT_ATLAS[Enum.PrimaryStat.Intellect] = PRIMARY_STAT_ATLAS.Intellect
PRIMARY_STAT_ATLAS[Enum.PrimaryStat.Spirit] = PRIMARY_STAT_ATLAS.Spirit
PRIMARY_STAT_ATLAS.STAT_STRENGTH = PRIMARY_STAT_ATLAS.Strength
PRIMARY_STAT_ATLAS.STAT_AGILITY = PRIMARY_STAT_ATLAS.Agility
PRIMARY_STAT_ATLAS.STAT_STAMINA = PRIMARY_STAT_ATLAS.Stamina
PRIMARY_STAT_ATLAS.STAT_DUALITY = PRIMARY_STAT_ATLAS.Duality
PRIMARY_STAT_ATLAS.STAT_INTELLECT = PRIMARY_STAT_ATLAS.Intellect
PRIMARY_STAT_ATLAS.STAT_SPIRIT = PRIMARY_STAT_ATLAS.Spirit

local PRIMARY_STAT1_DISPLAY_NAME = SPELL_STAT1_NAME or "Strength"
local PRIMARY_STAT2_DISPLAY_NAME = SPELL_STAT2_NAME or "Agility"
local PRIMARY_STAT3_DISPLAY_NAME = SPELL_STAT3_NAME or "Stamina"
local PRIMARY_STAT4_DISPLAY_NAME = SPELL_STAT4_NAME or "Intellect"
local PRIMARY_STAT5_DISPLAY_NAME = SPELL_STAT5_NAME or "Spirit"
local PRIMARY_STAT6_DISPLAY_NAME = PRIMARY_STAT6_NAME or "Duality"

PRIMARY_STAT_TEXT_WITH_ICON = {
	Strength = "|TInterface\\lfgframe\\PrimaryStatIcons:20:20:0:0:256:128:1:61:1:61|t |cffc69b6d" .. PRIMARY_STAT1_DISPLAY_NAME .. "|r",
	Agility = "|TInterface\\lfgframe\\PrimaryStatIcons:20:20:0:0:256:128:67:127:1:61|t |cfffff468" .. PRIMARY_STAT2_DISPLAY_NAME .. "|r",
	Stamina = "|TInterface\\lfgframe\\PrimaryStatIcons:20:20:0:0:256:128:129:189:1:61|t |cff7dc778" .. PRIMARY_STAT3_DISPLAY_NAME .. "|r",
	Duality = "|TInterface\\lfgframe\\PrimaryStatIcons:20:20:0:0:256:128:129:189:1:61|t |cff7dc778" .. PRIMARY_STAT6_DISPLAY_NAME .. "|r",
	Intellect = "|TInterface\\lfgframe\\PrimaryStatIcons:20:20:0:0:256:128:1:61:67:127|t |cff66bdd1" .. PRIMARY_STAT4_DISPLAY_NAME .. "|r",
	Spirit = "|TInterface\\lfgframe\\PrimaryStatIcons:20:20:0:0:256:128:67:127:67:127|t |cffffffff" .. PRIMARY_STAT5_DISPLAY_NAME .. "|r",
}
PRIMARY_STAT_TEXT_WITH_ICON[Enum.PrimaryStat.Strength] = PRIMARY_STAT_TEXT_WITH_ICON.Strength
PRIMARY_STAT_TEXT_WITH_ICON[Enum.PrimaryStat.Agility] = PRIMARY_STAT_TEXT_WITH_ICON.Agility
PRIMARY_STAT_TEXT_WITH_ICON[Enum.PrimaryStat.Stamina] = PRIMARY_STAT_TEXT_WITH_ICON.Stamina
PRIMARY_STAT_TEXT_WITH_ICON[Enum.PrimaryStat.Duality] = PRIMARY_STAT_TEXT_WITH_ICON.Duality
PRIMARY_STAT_TEXT_WITH_ICON[Enum.PrimaryStat.Intellect] = PRIMARY_STAT_TEXT_WITH_ICON.Intellect
PRIMARY_STAT_TEXT_WITH_ICON[Enum.PrimaryStat.Spirit] = PRIMARY_STAT_TEXT_WITH_ICON.Spirit
PRIMARY_STAT_TEXT_WITH_ICON.STAT_STRENGTH = PRIMARY_STAT_TEXT_WITH_ICON.Strength
PRIMARY_STAT_TEXT_WITH_ICON.STAT_AGILITY = PRIMARY_STAT_TEXT_WITH_ICON.Agility
PRIMARY_STAT_TEXT_WITH_ICON.STAT_STAMINA = PRIMARY_STAT_TEXT_WITH_ICON.Stamina
PRIMARY_STAT_TEXT_WITH_ICON.STAT_DUALITY = PRIMARY_STAT_TEXT_WITH_ICON.Duality
PRIMARY_STAT_TEXT_WITH_ICON.STAT_INTELLECT = PRIMARY_STAT_TEXT_WITH_ICON.Intellect
PRIMARY_STAT_TEXT_WITH_ICON.STAT_SPIRIT = PRIMARY_STAT_TEXT_WITH_ICON.Spirit

FACTION_STANDING_COLORS = {
	[1] = CreateColor(0.8, 0.3, 0.22),
	[2] = CreateColor(0.8, 0.3, 0.22),
	[3] = CreateColor(0.75, 0.27, 0),
	[4] = CreateColor(0.9, 0.7, 0),
	[5] = CreateColor(0, 0.6, 0.1),
	[6] = CreateColor(0, 0.6, 0.1),
	[7] = CreateColor(0, 0.6, 0.1),
	[8] = CreateColor(0, 0.6, 0.1),
};

POWER_COLORS = {
	HEALTH = CreateColor(1, 0.42, 0.42),
	MANA = CreateColor(0, 0.64, 1),
	RAGE = CreateColor(1, 0, 0),
	FOCUS = CreateColor(1, 0.50, 0.25),
	ENERGY = CreateColor(1, 1, 0),
	RUNES = CreateColor(0, 0.82, 1),
	RUNIC_POWER = CreateColor(0, 0.82, 1),
	INSANITY = CreateColor(0.4, 0, 0.8),
	DOOM_VOID = CreateColor(0.5, 0.32, 0.55),
	FLESH_ORBS = CreateColor(1, 0.61, 0),
	MONK_RUNES = CreateColor(0.71, 1.00, 0.92),
	PYRO_BREATH = CreateColor(1, 0.30, 0.30),
	RANGER_COMBO_POINTS = CreateColor(1, 0.96, 0.41),
	SOULS = CreateColor(0.79, 0.26, 0.99),
	SPIRIT_CRYSTALS = CreateColor(0.2, 0.2, 0.98),
	STATIC = CreateColor(0, 0.5, 0.7),
	TINKER_AMMO = CreateColor(0.77, 0.77, 0.88),
}

CLASS_SORT_ORDER = {
	"HERO",
	"WARRIOR",
	"DEATHKNIGHT",
	"PALADIN",
	"PRIEST",
	"SHAMAN",
	"DRUID",
	"ROGUE",
	"MAGE",
	"WARLOCK",
	"HUNTER",
	"NECROMANCER",
	"PYROMANCER",
	"CULTIST",
	"STARCALLER",
	"SUNCLERIC",
	"TINKER",
	"SPIRITMAGE",
	"WILDWALKER",
	"REAPER",
	"PROPHET",
	"CHRONOMANCER",
	"SONOFARUGAL",
	"GUARDIAN",
	"STORMBRINGER",
	"DEMONHUNTER",
	"BARBARIAN",
	"WITCHDOCTOR",
	"WITCHHUNTER",
	"FLESHWARDEN",
	"MONK",
	"RANGER",
};

MAX_CLASSES = #CLASS_SORT_ORDER;

CLASS_ENUM_TO_CLASS_FILE = {
	CLASS_WARRIOR = "WARRIOR",
	CLASS_PALADIN = "PALADIN",
	CLASS_HUNTER = "HUNTER",
	CLASS_ROGUE = "ROGUE",
	CLASS_PRIEST = "PRIEST",
	CLASS_DEATH_KNIGHT = "DEATHKNIGHT",
	CLASS_SHAMAN = "SHAMAN",
	CLASS_MAGE = "MAGE",
	CLASS_WARLOCK = "WARLOCK",
	CLASS_HERO = "HERO",
	CLASS_DRUID = "DRUID",
	CLASS_BARBARIAN = "BARBARIAN",
	CLASS_WITCH_DOCTOR = "WITCHDOCTOR",
	CLASS_DEMON_HUNTER = "DEMONHUNTER",
	CLASS_WITCH_HUNTER = "WITCHHUNTER",
	CLASS_STORMBRINGER = "STORMBRINGER",
	CLASS_KNIGHT_OF_XOROTH = "FLESHWARDEN",
	CLASS_GUARDIAN = "GUARDIAN",
	CLASS_MONK = "MONK",
	CLASS_SON_OF_ARUGAL = "SONOFARUGAL",
	CLASS_RANGER = "RANGER",
	CLASS_CHRONOMANCER = "CHRONOMANCER",
	CLASS_NECROMANCER = "NECROMANCER",
	CLASS_PYROMANCER = "PYROMANCER",
	CLASS_CULTIST = "CULTIST",
	CLASS_STARCALLER = "STARCALLER",
	CLASS_SUN_CLERIC = "SUNCLERIC",
	CLASS_TINKER = "TINKER",
	CLASS_VENOMANCER = "PROPHET",
	CLASS_REAPER = "REAPER",
	CLASS_PRIMALIST = "WILDWALKER",
	CLASS_RUNEMASTER = "SPIRITMAGE",
}


NUMBER_ABBREVIATION_DATA = {
	-- Order these from largest to smallest
	-- (significandDivisor and fractionDivisor should multiply to be equal to breakpoint)
	{ breakpoint = 10000000000000,	abbreviation = FOURTH_NUMBER_CAP_NO_SPACE,		significandDivisor = 1000000000000,	fractionDivisor = 1 },
	{ breakpoint = 1000000000000,	abbreviation = FOURTH_NUMBER_CAP_NO_SPACE,		significandDivisor = 100000000000,	fractionDivisor = 10 },
	{ breakpoint = 10000000000,		abbreviation = THIRD_NUMBER_CAP_NO_SPACE,		significandDivisor = 1000000000,	fractionDivisor = 1 },
	{ breakpoint = 1000000000,		abbreviation = THIRD_NUMBER_CAP_NO_SPACE,		significandDivisor = 100000000,	fractionDivisor = 10 },
	{ breakpoint = 10000000,		abbreviation = SECOND_NUMBER_CAP_NO_SPACE,		significandDivisor = 1000000,	fractionDivisor = 1 },
	{ breakpoint = 1000000,			abbreviation = SECOND_NUMBER_CAP_NO_SPACE,		significandDivisor = 100000,		fractionDivisor = 10 },
	{ breakpoint = 10000,			abbreviation = FIRST_NUMBER_CAP_NO_SPACE,		significandDivisor = 1000,		fractionDivisor = 1 },
	{ breakpoint = 1000,			abbreviation = FIRST_NUMBER_CAP_NO_SPACE,		significandDivisor = 100,		fractionDivisor = 10 },
}

function AbbreviateNumbers(value)
	for i, data in ipairs(NUMBER_ABBREVIATION_DATA) do
		if value >= data.breakpoint then
			local finalValue = math.floor(value / data.significandDivisor) / data.fractionDivisor;
			return finalValue .. (data.abbreviation)
		end
	end
	return tostring(value);
end

HTML_TAG_WRAPPER = [[<html><body>%s</body></html>]]

ARCHETYPE_PREVIEW_VOLUME = 100
