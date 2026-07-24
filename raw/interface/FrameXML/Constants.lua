--
-- New constants should be added to this file and other constants
-- deprecated and moved to this file.
--
COA_AUTO_SHOW_TALENTS_LEVEL = 10

AUTO_QUEST_RANK_UP_SPELLS_LEVEL = 11

CHAT_FONT_HEIGHTS = {
	[1] = 12,
	[2] = 14,
	[3] = 16,
	[4] = 18
};

GM_CHAT_BADGE = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz.blp:0:2.5:4:-3|t "

MATERIAL_TEXT_COLOR_TABLE = {
	["Default"]   = { 0.18, 0.12, 0.06 },
	["Stone"]     = { 1.0, 1.0, 1.0 },
	["Parchment"] = { 0.18, 0.12, 0.06 },
	["Marble"]    = { 0, 0, 0 },
	["Silver"]    = { 0.12, 0.12, 0.12 },
	["Bronze"]    = { 0.18, 0.12, 0.06 }
};
MATERIAL_TITLETEXT_COLOR_TABLE = {
	["Default"]   = { 0, 0, 0 },
	["Stone"]     = { 0.93, 0.82, 0 },
	["Parchment"] = { 0, 0, 0 },
	["Marble"]    = { 0.93, 0.82, 0 },
	["Silver"]    = { 0.93, 0.82, 0 },
	["Bronze"]    = { 0.93, 0.82, 0 }
};

-- 
-- Class
--

CHARACTER_ADVANCEMENT_CLASS_ORDER = {
	"DEATHKNIGHT",
	"DRUID",
	"HUNTER",
	"MAGE",
	"PALADIN",
	"PRIEST",
	"ROGUE",
	"SHAMAN",
	"WARLOCK",
	"WARRIOR",
}

CHARACTER_ADVANCEMENT_SUMMARY_CLASS_ORDER = {
	"DEATHKNIGHT",
	"DRUID",
	"HUNTER",
	"MAGE",
	"PALADIN",
	"PRIEST",
	"ROGUE",
	"SHAMAN",
	"WARLOCK",
	"WARRIOR",
	"HERO",
}

CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER = {
	["DEATHKNIGHT"] = { "BLOOD", "FROST", "UNHOLY" },
	["DRUID"] = { "BALANCE", "FERAL", "RESTORATION" },
	["HUNTER"] = { "BEASTMASTERY", "MARKSMANSHIP", "SURVIVAL" },
	["MAGE"] = { "ARCANE", "FIRE", "FROST" },
	["PALADIN"] = { "HOLY", "PROTECTION", "RETRIBUTION" },
	["PRIEST"] = { "DISCIPLINE", "HOLY", "SHADOW" },
	["ROGUE"] = { "ASSASSINATION", "COMBAT", "SUBTLETY" },
	["SHAMAN"] = { "ELEMENTAL", "ENHANCEMENT", "RESTORATION" },
	["WARLOCK"] = { "AFFLICTION", "DEMONOLOGY", "DESTRUCTION" },
	["WARRIOR"] = { "ARMS", "FURY", "PROTECTION" },
}

--
-- Hit Caps
--
if C_Config.GetBoolConfig("CONFIG_USE_CUSTOM_BASE_MISS_CHANCE") then
	HIT_CAP_MELEE = 14
	HIT_CAP_RANGED = 14
	HIT_CAP_SPELLS = 14
	HIT_CAP_AUTO_ATTACK = 33
	HIT_CAP_AUTO_ATTACK_PVP = 29
else
	HIT_CAP_MELEE = 8
	HIT_CAP_RANGED = 8
	HIT_CAP_SPELLS = 17
	HIT_CAP_AUTO_ATTACK = 27
	HIT_CAP_AUTO_ATTACK_PVP = 23
end
HIT_CAP_TITANS_GRIP_REDUCTION = 6

HIT_CAP_MELEE_PVP = 5
HIT_CAP_RANGED_PVP = 5
HIT_CAP_SPELLS_PVP = 4
--
-- Spell
--

-- Power Types
SPELL_POWER_MANA = 0;
SPELL_POWER_RAGE = 1;
SPELL_POWER_FOCUS = 2;
SPELL_POWER_ENERGY = 3;
SPELL_POWER_HAPPINESS = 4;
SPELL_POWER_RUNES = 5;
SPELL_POWER_RUNIC_POWER = 6;
SPELL_POWER_CUSTOM = 2;

SCHOOL_MASK_NONE = 0x00;
SCHOOL_MASK_PHYSICAL = 0x01;
SCHOOL_MASK_HOLY = 0x02;
SCHOOL_MASK_FIRE = 0x04;
SCHOOL_MASK_NATURE = 0x08;
SCHOOL_MASK_FROST = 0x10;
SCHOOL_MASK_SHADOW = 0x20;
SCHOOL_MASK_ARCANE = 0x40;

SCHOOL_STRING_TABLE = {
	-- Single Schools
	[SCHOOL_MASK_PHYSICAL]                                                                                                                          = STRING_SCHOOL_PHYSICAL,
	[SCHOOL_MASK_HOLY]                                                                                                                              = STRING_SCHOOL_HOLY,
	[SCHOOL_MASK_FIRE]                                                                                                                              = STRING_SCHOOL_FIRE,
	[SCHOOL_MASK_NATURE]                                                                                                                            = STRING_SCHOOL_NATURE,
	[SCHOOL_MASK_FROST]                                                                                                                             = STRING_SCHOOL_FROST,
	[SCHOOL_MASK_SHADOW]                                                                                                                            = STRING_SCHOOL_SHADOW,
	[SCHOOL_MASK_ARCANE]                                                                                                                            = STRING_SCHOOL_ARCANE,
	-- Physical and a Magical
	[SCHOOL_MASK_PHYSICAL + SCHOOL_MASK_FIRE]                                                                                                       = STRING_SCHOOL_FIRESTRIKE or "STRING_SCHOOL_FIRESTRIKE",
	[SCHOOL_MASK_PHYSICAL + SCHOOL_MASK_FROST]                                                                                                      = STRING_SCHOOL_FROSTSTRIKE,
	[SCHOOL_MASK_PHYSICAL + SCHOOL_MASK_ARCANE]                                                                                                     = STRING_SCHOOL_SPELLSTRIKE,
	[SCHOOL_MASK_PHYSICAL + SCHOOL_MASK_NATURE]                                                                                                     = STRING_SCHOOL_STORMSTRIKE,
	[SCHOOL_MASK_PHYSICAL + SCHOOL_MASK_SHADOW]                                                                                                     = STRING_SCHOOL_SHADOWSTRIKE,
	[SCHOOL_MASK_PHYSICAL + SCHOOL_MASK_HOLY]                                                                                                       = STRING_SCHOOL_HOLYSTRIKE,
	-- Two Magical Schools
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_FROST]                                                                                                          = STRING_SCHOOL_FROSTFIRE,
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_ARCANE]                                                                                                         = STRING_SCHOOL_SPELLFIRE,
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_NATURE]                                                                                                         = STRING_SCHOOL_FIRESTORM,
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_SHADOW]                                                                                                         = STRING_SCHOOL_SHADOWFLAME,
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_HOLY]                                                                                                           = STRING_SCHOOL_HOLYFIRE,
	[SCHOOL_MASK_FROST + SCHOOL_MASK_ARCANE]                                                                                                        = STRING_SCHOOL_SPELLFROST,
	[SCHOOL_MASK_FROST + SCHOOL_MASK_NATURE]                                                                                                        = STRING_SCHOOL_FROSTSTORM,
	[SCHOOL_MASK_FROST + SCHOOL_MASK_SHADOW]                                                                                                        = STRING_SCHOOL_SHADOWFROST,
	[SCHOOL_MASK_FROST + SCHOOL_MASK_HOLY]                                                                                                          = STRING_SCHOOL_HOLYFROST,
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_NATURE]                                                                                                       = STRING_SCHOOL_SPELLSTORM,
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_SHADOW]                                                                                                       = STRING_SCHOOL_SPELLSHADOW,
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_HOLY]                                                                                                         = STRING_SCHOOL_DIVINE,
	[SCHOOL_MASK_NATURE + SCHOOL_MASK_SHADOW]                                                                                                       = STRING_SCHOOL_SHADOWSTORM,
	[SCHOOL_MASK_NATURE + SCHOOL_MASK_HOLY]                                                                                                         = STRING_SCHOOL_HOLYSTORM,
	[SCHOOL_MASK_SHADOW + SCHOOL_MASK_HOLY]                                                                                                         = STRING_SCHOOL_SHADOWLIGHT,
	-- Three or more schools
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_FROST + SCHOOL_MASK_NATURE]                                                                                     = STRING_SCHOOL_ELEMENTAL,
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_FROST + SCHOOL_MASK_ARCANE + SCHOOL_MASK_NATURE + SCHOOL_MASK_SHADOW]                                           = STRING_SCHOOL_CHROMATIC,
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_FROST + SCHOOL_MASK_ARCANE + SCHOOL_MASK_NATURE + SCHOOL_MASK_SHADOW + SCHOOL_MASK_HOLY]                        = STRING_SCHOOL_MAGIC,
	[SCHOOL_MASK_PHYSICAL + SCHOOL_MASK_FIRE + SCHOOL_MASK_FROST + SCHOOL_MASK_ARCANE + SCHOOL_MASK_NATURE + SCHOOL_MASK_SHADOW + SCHOOL_MASK_HOLY] = STRING_SCHOOL_CHAOS,
}

CLASS_ALTERNATE_POWERS = {
	WITCHHUNTER = "RAGE",
	NECROMANCER = "MANA",
	STARCALLER = "ENERGY",
	PROPHET = "MANA", -- venomancer
	WILDWALKER = "RAGE", -- primalist
}

-- Stats
BONUS_WEAPON_DAMAGE_PER_SPELLPOWER = 1/14

-- 
-- Talent
-- 

local IsHero = function() return select(2, UnitClass("player")) == "HERO"  end
SHOW_TALENT_LEVEL = 10;
SHOW_PVP_LEVEL = 10;
SHOW_LFD_LEVEL = IsHero() and 10 or 15;

TALENT_SORT_ORDER = {
	"spec1",
	"spec2",
	"petspec1",
};

TALENT_ACTIVATION_SPELLS = {
	63645,
	63644,
};

--
-- Glyph
--
SHOW_INSCRIPTION_LEVEL = 15;

--
-- Achievement
--

-- Criteria Types
CRITERIA_TYPE_ACHIEVEMENT = 8;

-- Achievement Flags
ACHIEVEMENT_FLAGS_STATISTIC = 0x00000001;
ACHIEVEMENT_FLAGS_HIDDEN = 0x00000002;
ACHIEVEMENT_FLAGS_HAS_PROGRESS_BAR = 0x00000080;
NUM_ACHIEVEMENT_FLAGS = 3;

-- Criteria Flags
ACHIEVEMENT_CRITERIA_PROGRESS_BAR = 0x00000001;
ACHIEVEMENT_CRITERIA_HIDDEN = 0x00000002;
NUM_ACHIEVEMENT_CRITERIA_FLAGS = 2;

--
-- Inventory
--
NEW_ITEM_ATLAS_BY_QUALITY = {
	[Enum.ItemQuality.Poor]      = "bags-glow-white",
	[Enum.ItemQuality.Common]    = "bags-glow-white",
	[Enum.ItemQuality.Uncommon]  = "bags-glow-green",
	[Enum.ItemQuality.Rare]      = "bags-glow-blue",
	[Enum.ItemQuality.Epic]      = "bags-glow-purple",
	[Enum.ItemQuality.Legendary] = "bags-glow-orange",
	[Enum.ItemQuality.Vanity]    = "bags-glow-artifact",
	[Enum.ItemQuality.Heirloom]  = "bags-glow-heirloom",
};

-- General item constants
ITEM_UNIQUE_EQUIPPED = -1;
MAX_NUM_SOCKETS = 3;

-- Key Item Text Format Strings
MARKUP_AE_ICON = "|TInterface\\Icons\\inv_custom_abilityessence:18:18|t"
MARKUP_TE_ICON = "|TInterface\\Icons\\inv_custom_talentessence:18:18|t"
MARKUP_MARKS_ICON = "|TInterface\\Icons\\Mail_GMIcon:18:18|t"
MARKUP_RARITY_GEM0 = "|TInterface\\Collections\\RarityGemAtlas:25:25:0:-1:128:128:96:128:64:96|t"
MARKUP_RARITY_GEM1 = "|TInterface\\Collections\\RarityGemAtlas:25:25:0:-1:128:128:0:32:64:96|t"
MARKUP_RARITY_GEM2 = "|TInterface\\Collections\\RarityGemAtlas:25:25:0:-1:128:128:0:32:32:64|t"
MARKUP_RARITY_GEM3 = "|TInterface\\Collections\\RarityGemAtlas:25:25:0:-1:128:128:32:64:32:64|t"
MARKUP_RARITY_GEM4 = "|TInterface\\Collections\\RarityGemAtlas:25:25:0:-1:128:128:64:96:32:64|t"
MARKUP_RARITY_GEM5 = "|TInterface\\Collections\\RarityGemAtlas:25:25:0:-1:128:128:96:128:32:64|t"
MARKUP_RARITY_GEM6 = "|TInterface\\Collections\\RarityGemAtlas:25:25:0:-1:128:128:32:64:64:96|t"
MARKUP_RARITY_GEM7 = "|TInterface\\Collections\\RarityGemAtlas:25:25:0:-1:128:128:64:96:64:96|t"

-- Item quality
ITEM_QUALITY_POOR = 0;
ITEM_QUALITY_COMMON = 1;
ITEM_QUALITY_UNCOMMON = 2;
ITEM_QUALITY_RARE = 3;
ITEM_QUALITY_EPIC = 4;

-- Equipment Flyout
EQUIPMENT_FLYOUT_MAX_ITEMS = 23
EQUIPMENT_MANAGER_COLUMNS = 5
EQUIPMENT_MANAGER_PLACEINBAGS_LOCATION = 0xFFFFFFFF
EQUIPMENT_MANAGER_IGNORESLOT_LOCATION = 0xFFFFFFFE
EQUIPMENT_MANAGER_UNIGNORESLOT_LOCATION = 0xFFFFFFFD
EQUIPMENT_MANAGER_PLACEINBANK_LOCATION =  0xFFFFFFFC
EQUIPMENT_MANAGER_FIRST_SPECIAL_LOCATION = EQUIPMENT_MANAGER_PLACEINBANK_LOCATION

-- Item location bitflags
ITEM_INVENTORY_LOCATION_PLAYER = 0x00100000;
ITEM_INVENTORY_LOCATION_BAGS = 0x00200000;
ITEM_INVENTORY_LOCATION_BANK = 0x00400000;
ITEM_INVENTORY_BAG_BIT_OFFSET = 8; -- Number of bits that the bag index in GetInventoryItemsForSlot gets shifted to the left.

-- Inventory slots
INVSLOT_AMMO = 0;
INVSLOT_HEAD = 1;
INVSLOT_FIRST_EQUIPPED = INVSLOT_HEAD;
INVSLOT_NECK = 2;
INVSLOT_SHOULDER = 3;
INVSLOT_BODY = 4;
INVSLOT_CHEST = 5;
INVSLOT_WAIST = 6;
INVSLOT_LEGS = 7;
INVSLOT_FEET = 8;
INVSLOT_WRIST = 9;
INVSLOT_HAND = 10;
INVSLOT_FINGER1 = 11;
INVSLOT_FINGER2 = 12;
INVSLOT_TRINKET1 = 13;
INVSLOT_TRINKET2 = 14;
INVSLOT_BACK = 15;
INVSLOT_MAINHAND = 16;
INVSLOT_OFFHAND = 17;
INVSLOT_RANGED = 18;
INVSLOT_TABARD = 19;
INVSLOT_LAST_EQUIPPED = INVSLOT_TABARD;

INVSLOT_ILVL_IGNORED = {
	[INVSLOT_TABARD] = true,
	[INVSLOT_RANGED] = true,
	[INVSLOT_OFFHAND] = true,
	[INVSLOT_BODY] = true,
}

INVSLOT_TO_SLOTNAME = {
	[INVSLOT_AMMO] = "AmmoSlot",
	[INVSLOT_HEAD] = "HeadSlot",
	[INVSLOT_NECK] = "NeckSlot",
	[INVSLOT_SHOULDER] = "ShoulderSlot",
	[INVSLOT_BODY] = "ShirtSlot",
	[INVSLOT_CHEST] = "ChestSlot",
	[INVSLOT_WAIST] = "WaistSlot",
	[INVSLOT_LEGS] = "LegsSlot",
	[INVSLOT_FEET] = "FeetSlot",
	[INVSLOT_WRIST] = "WristSlot",
	[INVSLOT_HAND] = "HandsSlot",
	[INVSLOT_FINGER1] = "Finger0Slot",
	[INVSLOT_FINGER2] = "Finger1Slot",
	[INVSLOT_TRINKET1] = "Trinket0Slot",
	[INVSLOT_TRINKET2] = "Trinket1Slot",
	[INVSLOT_BACK] = "BackSlot",
	[INVSLOT_MAINHAND] = "MainHandSlot",
	[INVSLOT_OFFHAND] = "SecondaryHandSlot",
	[INVSLOT_RANGED] = "RangedSlot",
	[INVSLOT_TABARD] = "TabardSlot",
}

INVTYPE_SET = "INVTYPE_SET"

INVSLOTS_EQUIPABLE_IN_COMBAT = {
	[INVSLOT_MAINHAND] = true,
	[INVSLOT_OFFHAND]  = true,
	[INVSLOT_RANGED]   = true,
}

INVTYPE_TO_INVSLOT = {
	["INVTYPE_HEAD"]           = INVSLOT_HEAD,
	["INVTYPE_NECK"]           = INVSLOT_NECK,
	["INVTYPE_SHOULDER"]       = INVSLOT_SHOULDER,
	["INVTYPE_BODY"]           = INVSLOT_BODY,
	["INVTYPE_CHEST"]          = INVSLOT_CHEST,
	["INVTYPE_WAIST"]          = INVSLOT_WAIST,
	["INVTYPE_LEGS"]           = INVSLOT_LEGS,
	["INVTYPE_FEET"]           = INVSLOT_FEET,
	["INVTYPE_WRIST"]          = INVSLOT_WRIST,
	["INVTYPE_HAND"]           = INVSLOT_HAND,
	["INVTYPE_FINGER"]         = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
	["INVTYPE_TRINKET"]        = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
	["INVTYPE_WEAPON"]         = INVSLOT_MAINHAND,
	["INVTYPE_SHIELD"]         = INVSLOT_OFFHAND,
	["INVTYPE_RANGED"]         = INVSLOT_RANGED,
	["INVTYPE_CLOAK"]          = INVSLOT_BACK,
	["INVTYPE_2HWEAPON"]       = INVSLOT_MAINHAND,
	["INVTYPE_TABARD"]         = INVSLOT_TABARD,
	["INVTYPE_ROBE"]           = INVSLOT_CHEST,
	["INVTYPE_WEAPONMAINHAND"] = INVSLOT_MAINHAND,
	["INVTYPE_WEAPONOFFHAND"]  = INVSLOT_OFFHAND,
	["INVTYPE_HOLDABLE"]       = INVSLOT_OFFHAND,
	["INVTYPE_AMMO"]           = INVSLOT_AMMO,
	["INVTYPE_THROWN"]         = INVSLOT_RANGED,
	["INVTYPE_RANGEDRIGHT"]    = INVSLOT_RANGED,
	["INVTYPE_RELIC"]          = INVSLOT_RANGED,
}

INVTYPE_MASK_NAME = {
	[Enum.InventoryTypeMask.NonEquip]        = ERR_NOT_EQUIPPABLE,
	[Enum.InventoryTypeMask.Head]            = INVTYPE_HEAD,
	[Enum.InventoryTypeMask.Necklace]        = INVTYPE_NECK,
	[Enum.InventoryTypeMask.Shoulders]       = INVTYPE_SHOULDER,
	[Enum.InventoryTypeMask.Body]            = INVTYPE_BODY,
	[Enum.InventoryTypeMask.Chest]           = INVTYPE_CHEST,
	[Enum.InventoryTypeMask.Waist]           = INVTYPE_WAIST,
	[Enum.InventoryTypeMask.Legs]            = INVTYPE_LEGS,
	[Enum.InventoryTypeMask.Feet]            = INVTYPE_FEET,
	[Enum.InventoryTypeMask.Wrists]          = INVTYPE_WRIST,
	[Enum.InventoryTypeMask.Hands]           = INVTYPE_HAND,
	[Enum.InventoryTypeMask.Finger]          = INVTYPE_FINGER,
	[Enum.InventoryTypeMask.Trinket]         = INVTYPE_TRINKET,
	[Enum.InventoryTypeMask.Weapon]          = INVTYPE_WEAPON,
	[Enum.InventoryTypeMask.Shield]          = INVTYPE_SHIELD,
	[Enum.InventoryTypeMask.Ranged]          = INVTYPE_RANGED,
	[Enum.InventoryTypeMask.Cloak]           = INVTYPE_CLOAK,
	[Enum.InventoryTypeMask.TwoHandedWeapon] = INVTYPE_2HWEAPON,
	[Enum.InventoryTypeMask.Bag]             = INVTYPE_BAG,
	[Enum.InventoryTypeMask.Tabard]          = INVTYPE_TABARD,
	[Enum.InventoryTypeMask.Robe]            = INVTYPE_ROBE,
	[Enum.InventoryTypeMask.MainHand]        = INVTYPE_WEAPONMAINHAND,
	[Enum.InventoryTypeMask.OffHand]         = INVTYPE_WEAPONOFFHAND,
	[Enum.InventoryTypeMask.Holdable]        = INVTYPE_HOLDABLE,
	[Enum.InventoryTypeMask.Ammo]            = INVTYPE_AMMO,
	[Enum.InventoryTypeMask.Thrown]          = INVTYPE_THROWN,
	[Enum.InventoryTypeMask.RangedRight]     = INVTYPE_RANGEDRIGHT,
	[Enum.InventoryTypeMask.Quiver]          = INVTYPE_QUIVER,
	[Enum.InventoryTypeMask.Relic]           = INVTYPE_RELIC,
}

ITEM_SUBCLASS_MASK_NAME = {
	[Enum.EquippedItemClass.Bag]               = ITEM_SUBCLASS_1_0,
	[Enum.EquippedItemClass.SoulBag]           = ITEM_SUBCLASS_1_1,
	[Enum.EquippedItemClass.HerbBag]           = ITEM_SUBCLASS_1_2,
	[Enum.EquippedItemClass.EnchantingBag]     = ITEM_SUBCLASS_1_3,
	[Enum.EquippedItemClass.EngineeringBag]    = ITEM_SUBCLASS_1_4,
	[Enum.EquippedItemClass.GemBag]            = ITEM_SUBCLASS_1_5,
	[Enum.EquippedItemClass.MiningBag]         = ITEM_SUBCLASS_1_6,
	[Enum.EquippedItemClass.LeatherworkingBag] = ITEM_SUBCLASS_1_7,
	[Enum.EquippedItemClass.InscriptionBag]    = ITEM_SUBCLASS_1_8,
	[Enum.EquippedItemClass.Axe1H]             = ITEM_SUBCLASS_2_0,
	[Enum.EquippedItemClass.Axe2H]             = ITEM_SUBCLASS_2_1,
	[Enum.EquippedItemClass.Bow]               = ITEM_SUBCLASS_2_2,
	[Enum.EquippedItemClass.Gun]               = ITEM_SUBCLASS_2_3,
	[Enum.EquippedItemClass.Mace1H]            = ITEM_SUBCLASS_2_4,
	[Enum.EquippedItemClass.Mace2H]            = ITEM_SUBCLASS_2_5,
	[Enum.EquippedItemClass.Polearm]           = ITEM_SUBCLASS_2_6,
	[Enum.EquippedItemClass.Sword1H]           = ITEM_SUBCLASS_2_7,
	[Enum.EquippedItemClass.Sword2H]           = ITEM_SUBCLASS_2_8,
	[Enum.EquippedItemClass.Obsolete]          = ITEM_SUBCLASS_2_9,
	[Enum.EquippedItemClass.Staff]             = ITEM_SUBCLASS_2_10,
	--[Enum.EquippedItemClass.Exotic1H]          = ITEM_SUBCLASS_2_11,
	--[Enum.EquippedItemClass.Exotic2H]          = ITEM_SUBCLASS_2_12,
	[Enum.EquippedItemClass.Fist]              = ITEM_SUBCLASS_2_13,
	[Enum.EquippedItemClass.Misc]              = ITEM_SUBCLASS_2_14,
	[Enum.EquippedItemClass.Dagger]            = ITEM_SUBCLASS_2_15,
	[Enum.EquippedItemClass.Thrown]            = ITEM_SUBCLASS_2_16,
	[Enum.EquippedItemClass.Spear]             = ITEM_SUBCLASS_2_17,
	[Enum.EquippedItemClass.Crossbow]          = ITEM_SUBCLASS_2_18,
	[Enum.EquippedItemClass.Wand]              = ITEM_SUBCLASS_2_19,
	[Enum.EquippedItemClass.FishingPole]       = ITEM_SUBCLASS_2_20,
	[Enum.EquippedItemClass.Red]               = ITEM_SUBCLASS_3_0,
	[Enum.EquippedItemClass.Blue]              = ITEM_SUBCLASS_3_1,
	[Enum.EquippedItemClass.Yellow]            = ITEM_SUBCLASS_3_2,
	[Enum.EquippedItemClass.Purple]            = ITEM_SUBCLASS_3_3,
	[Enum.EquippedItemClass.Green]             = ITEM_SUBCLASS_3_4,
	[Enum.EquippedItemClass.Orange]            = ITEM_SUBCLASS_3_5,
	[Enum.EquippedItemClass.Meta]              = ITEM_SUBCLASS_3_6,
	[Enum.EquippedItemClass.Simple]            = ITEM_SUBCLASS_3_7,
	[Enum.EquippedItemClass.Prismatic]         = ITEM_SUBCLASS_3_8,
	[Enum.EquippedItemClass.Misc]              = ITEM_SUBCLASS_4_0,
	[Enum.EquippedItemClass.Cloth]             = ITEM_SUBCLASS_4_1,
	[Enum.EquippedItemClass.Leather]           = ITEM_SUBCLASS_4_2,
	[Enum.EquippedItemClass.Mail]              = ITEM_SUBCLASS_4_3,
	[Enum.EquippedItemClass.Plate]             = ITEM_SUBCLASS_4_4,
	[Enum.EquippedItemClass.Buckler]           = ITEM_SUBCLASS_4_5,
	[Enum.EquippedItemClass.Shield]            = ITEM_SUBCLASS_4_6,
	[Enum.EquippedItemClass.Libram]            = ITEM_SUBCLASS_4_7,
	[Enum.EquippedItemClass.Idol]              = ITEM_SUBCLASS_4_8,
	[Enum.EquippedItemClass.Totem]             = ITEM_SUBCLASS_4_9,
	[Enum.EquippedItemClass.Sigil]             = ITEM_SUBCLASS_4_10,
}
ITEM_SUBCLASS_TO_MASK = tinvert(ITEM_SUBCLASS_MASK_NAME)

-- inv type stuff
INVTYPE_INDEX_TO_STRING = {
	[0] = "INVTYPE_NON_EQUIP",
	[1] = "INVTYPE_HEAD",
	[2] = "INVTYPE_NECK",
	[3] = "INVTYPE_SHOULDERS",
	[4] = "INVTYPE_BODY",
	[5] = "INVTYPE_CHEST",
	[6] = "INVTYPE_WAIST",
	[7] = "INVTYPE_LEGS",
	[8] = "INVTYPE_FEET",
	[9] = "INVTYPE_WRISTS",
	[10] = "INVTYPE_HANDS",
	[11] = "INVTYPE_FINGER",
	[12] = "INVTYPE_TRINKET",
	[13] = "INVTYPE_WEAPON",
	[14] = "INVTYPE_SHIELD",
	[15] = "INVTYPE_RANGED",
	[16] = "INVTYPE_CLOAK",
	[17] = "INVTYPE_2HWEAPON",
	[18] = "INVTYPE_BAG",
	[19] = "INVTYPE_TABARD",
	[20] = "INVTYPE_ROBE",
	[21] = "INVTYPE_WEAPONMAINHAND",
	[22] = "INVTYPE_WEAPONOFFHAND",
	[23] = "INVTYPE_HOLDABLE",
	[24] = "INVTYPE_AMMO",
	[25] = "INVTYPE_THROWN",
	[26] = "INVTYPE_RANGEDRIGHT",
	[27] = "INVTYPE_QUIVER",
	[28] = "INVTYPE_RELIC",
}

INVTYPE_INDEX_TO_SLOT = {
	[1] =	INVSLOT_HEAD, -- INVTYPE_HEAD
	[2] =	INVSLOT_NECK, -- INVTYPE_NECK
	[3] =	INVSLOT_SHOULDER, -- INVTYPE_SHOULDERS
	[4] =	INVSLOT_BODY, -- INVTYPE_BODY
	[5] =	INVSLOT_CHEST, -- INVTYPE_CHEST
	[6] =	INVSLOT_WAIST, -- INVTYPE_WAIST
	[7] =	INVSLOT_LEGS, -- INVTYPE_LEGS
	[8] =	INVSLOT_FEET, -- INVTYPE_FEET
	[9] =	INVSLOT_WRIST, -- INVTYPE_WRISTS
	[10] =	INVSLOT_HAND, -- INVTYPE_HANDS
	[11] =	INVSLOT_FINGER1, -- INVTYPE_FINGER
	[12] =	INVSLOT_TRINKET1, -- INVTYPE_TRINKET
	[13] =	INVSLOT_MAINHAND, -- INVTYPE_WEAPON
	[14] =	INVSLOT_OFFHAND, -- INVTYPE_SHIELD
	[15] =	INVSLOT_RANGED, -- INVTYPE_RANGED
	[16] =	INVSLOT_BACK, -- INVTYPE_CLOAK
	[17] =	INVSLOT_MAINHAND, -- INVTYPE_2HWEAPON
	[19] = 	INVSLOT_TABARD,-- INVTYPE_TABARD
	[20] =	INVSLOT_CHEST, -- INVTYPE_ROBE
	[21] =	INVSLOT_MAINHAND, -- INVTYPE_WEAPONMAINHAND
	[22] =	INVSLOT_OFFHAND, -- INVTYPE_WEAPONOFFHAND
	[23] =	INVSLOT_OFFHAND, -- INVTYPE_HOLDABLE
	[24] = 	INVSLOT_AMMO, -- INVTYPE_AMMO
	[25] = 	INVSLOT_RANGED, -- INVTYPE_THROWN
	[26] =	INVSLOT_RANGED, -- INVTYPE_RANGEDRIGHT
	[28] =	INVSLOT_RANGED, -- INVTYPE_QUIVER
}

-- Container constants
ITEM_INVENTORY_BANK_BAG_OFFSET = 4; -- Number of bags before the first bank bag
CONTAINER_BAG_OFFSET = 19; -- Used for PutItemInBag

BACKPACK_CONTAINER = 0;
BANK_CONTAINER = -1;
BANK_CONTAINER_INVENTORY_OFFSET = 39; -- Used for PickupInventoryItem
KEYRING_CONTAINER = -2;

NUM_BAG_SLOTS = 4;
NUM_BANKGENERIC_SLOTS = 28;
NUM_BANKBAGSLOTS = 7;

--
-- Equipment Set
--
MAX_EQUIPMENT_SETS_PER_PLAYER = 20;
EQUIPMENT_SET_EMPTY_SLOT = 0;
EQUIPMENT_SET_IGNORED_SLOT = 1;
EQUIPMENT_SET_ITEM_MISSING = -1;

--
-- Combat Log
-- 

-- Affiliation
COMBATLOG_OBJECT_AFFILIATION_MINE = 0x00000001;
COMBATLOG_OBJECT_AFFILIATION_PARTY = 0x00000002;
COMBATLOG_OBJECT_AFFILIATION_RAID = 0x00000004;
COMBATLOG_OBJECT_AFFILIATION_OUTSIDER = 0x00000008;
COMBATLOG_OBJECT_AFFILIATION_MASK = 0x0000000F;
-- Reaction
COMBATLOG_OBJECT_REACTION_FRIENDLY = 0x00000010;
COMBATLOG_OBJECT_REACTION_NEUTRAL = 0x00000020;
COMBATLOG_OBJECT_REACTION_HOSTILE = 0x00000040;
COMBATLOG_OBJECT_REACTION_MASK = 0x000000F0;
-- Ownership
COMBATLOG_OBJECT_CONTROL_PLAYER = 0x00000100;
COMBATLOG_OBJECT_CONTROL_NPC = 0x00000200;
COMBATLOG_OBJECT_CONTROL_MASK = 0x00000300;
-- Unit type
COMBATLOG_OBJECT_TYPE_PLAYER = 0x00000400;
COMBATLOG_OBJECT_TYPE_NPC = 0x00000800;
COMBATLOG_OBJECT_TYPE_PET = 0x00001000;
COMBATLOG_OBJECT_TYPE_GUARDIAN = 0x00002000;
COMBATLOG_OBJECT_TYPE_OBJECT = 0x00004000;
COMBATLOG_OBJECT_TYPE_MASK = 0x0000FC00;

-- Special cases (non-exclusive)
COMBATLOG_OBJECT_TARGET = 0x00010000;
COMBATLOG_OBJECT_FOCUS = 0x00020000;
COMBATLOG_OBJECT_MAINTANK = 0x00040000;
COMBATLOG_OBJECT_MAINASSIST = 0x00080000;
COMBATLOG_OBJECT_RAIDTARGET1 = 0x00100000;
COMBATLOG_OBJECT_RAIDTARGET2 = 0x00200000;
COMBATLOG_OBJECT_RAIDTARGET3 = 0x00400000;
COMBATLOG_OBJECT_RAIDTARGET4 = 0x00800000;
COMBATLOG_OBJECT_RAIDTARGET5 = 0x01000000;
COMBATLOG_OBJECT_RAIDTARGET6 = 0x02000000;
COMBATLOG_OBJECT_RAIDTARGET7 = 0x04000000;
COMBATLOG_OBJECT_RAIDTARGET8 = 0x08000000;
COMBATLOG_OBJECT_NONE = 0x80000000;
COMBATLOG_OBJECT_SPECIAL_MASK = 0xFFFF0000;
COMBATLOG_OBJECT_RAIDTARGET_MASK = bit.bor(
		COMBATLOG_OBJECT_RAIDTARGET1,
		COMBATLOG_OBJECT_RAIDTARGET2,
		COMBATLOG_OBJECT_RAIDTARGET3,
		COMBATLOG_OBJECT_RAIDTARGET4,
		COMBATLOG_OBJECT_RAIDTARGET5,
		COMBATLOG_OBJECT_RAIDTARGET6,
		COMBATLOG_OBJECT_RAIDTARGET7,
		COMBATLOG_OBJECT_RAIDTARGET8
);

-- Object type constants
COMBATLOG_FILTER_ME = bit.bor(
		COMBATLOG_OBJECT_AFFILIATION_MINE,
		COMBATLOG_OBJECT_REACTION_FRIENDLY,
		COMBATLOG_OBJECT_CONTROL_PLAYER,
		COMBATLOG_OBJECT_TYPE_PLAYER
);

COMBATLOG_FILTER_MINE = bit.bor(
		COMBATLOG_OBJECT_AFFILIATION_MINE,
		COMBATLOG_OBJECT_REACTION_FRIENDLY,
		COMBATLOG_OBJECT_CONTROL_PLAYER,
		COMBATLOG_OBJECT_TYPE_PLAYER,
		COMBATLOG_OBJECT_TYPE_OBJECT
);

COMBATLOG_FILTER_MY_PET = bit.bor(
		COMBATLOG_OBJECT_AFFILIATION_MINE,
		COMBATLOG_OBJECT_REACTION_FRIENDLY,
		COMBATLOG_OBJECT_CONTROL_PLAYER,
		COMBATLOG_OBJECT_TYPE_GUARDIAN,
		COMBATLOG_OBJECT_TYPE_PET
);
COMBATLOG_FILTER_FRIENDLY_UNITS = bit.bor(
		COMBATLOG_OBJECT_AFFILIATION_PARTY,
		COMBATLOG_OBJECT_AFFILIATION_RAID,
		COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,
		COMBATLOG_OBJECT_REACTION_FRIENDLY,
		COMBATLOG_OBJECT_CONTROL_PLAYER,
		COMBATLOG_OBJECT_CONTROL_NPC,
		COMBATLOG_OBJECT_TYPE_PLAYER,
		COMBATLOG_OBJECT_TYPE_NPC,
		COMBATLOG_OBJECT_TYPE_PET,
		COMBATLOG_OBJECT_TYPE_GUARDIAN,
		COMBATLOG_OBJECT_TYPE_OBJECT
);

COMBATLOG_FILTER_HOSTILE_PLAYERS = bit.bor(
		COMBATLOG_OBJECT_AFFILIATION_PARTY,
		COMBATLOG_OBJECT_AFFILIATION_RAID,
		COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,
		COMBATLOG_OBJECT_REACTION_HOSTILE,
		COMBATLOG_OBJECT_CONTROL_PLAYER,
		COMBATLOG_OBJECT_TYPE_PLAYER,
		COMBATLOG_OBJECT_TYPE_NPC,
		COMBATLOG_OBJECT_TYPE_PET,
		COMBATLOG_OBJECT_TYPE_GUARDIAN,
		COMBATLOG_OBJECT_TYPE_OBJECT
);

COMBATLOG_FILTER_HOSTILE_UNITS = bit.bor(
		COMBATLOG_OBJECT_AFFILIATION_PARTY,
		COMBATLOG_OBJECT_AFFILIATION_RAID,
		COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,
		COMBATLOG_OBJECT_REACTION_HOSTILE,
		COMBATLOG_OBJECT_CONTROL_NPC,
		COMBATLOG_OBJECT_TYPE_PLAYER,
		COMBATLOG_OBJECT_TYPE_NPC,
		COMBATLOG_OBJECT_TYPE_PET,
		COMBATLOG_OBJECT_TYPE_GUARDIAN,
		COMBATLOG_OBJECT_TYPE_OBJECT
);

COMBATLOG_FILTER_NEUTRAL_UNITS = bit.bor(
		COMBATLOG_OBJECT_AFFILIATION_PARTY,
		COMBATLOG_OBJECT_AFFILIATION_RAID,
		COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,
		COMBATLOG_OBJECT_REACTION_NEUTRAL,
		COMBATLOG_OBJECT_CONTROL_PLAYER,
		COMBATLOG_OBJECT_CONTROL_NPC,
		COMBATLOG_OBJECT_TYPE_PLAYER,
		COMBATLOG_OBJECT_TYPE_NPC,
		COMBATLOG_OBJECT_TYPE_PET,
		COMBATLOG_OBJECT_TYPE_GUARDIAN,
		COMBATLOG_OBJECT_TYPE_OBJECT
);
COMBATLOG_FILTER_UNKNOWN_UNITS = COMBATLOG_OBJECT_NONE;
COMBATLOG_FILTER_EVERYTHING = 0xFFFFFFFF;

--
-- Calendar
-- 
CALENDAR_FIRST_WEEKDAY = 1;        -- 1=SUN 2=MON 3=TUE 4=WED 5=THU 6=FRI 7=SAT

-- Event Types
CALENDAR_EVENTTYPE_RAID = 1;
CALENDAR_EVENTTYPE_DUNGEON = 2;
CALENDAR_EVENTTYPE_PVP = 3;
CALENDAR_EVENTTYPE_MEETING = 4;
CALENDAR_EVENTTYPE_OTHER = 5;
CALENDAR_MAX_EVENTTYPE = CALENDAR_EVENTTYPE_OTHER;

-- Invite Statuses
CALENDAR_INVITESTATUS_INVITED = 1;
CALENDAR_INVITESTATUS_ACCEPTED = 2;
CALENDAR_INVITESTATUS_DECLINED = 3;
CALENDAR_INVITESTATUS_CONFIRMED = 4;
CALENDAR_INVITESTATUS_OUT = 5;
CALENDAR_INVITESTATUS_STANDBY = 6;
CALENDAR_INVITESTATUS_SIGNEDUP = 7;
CALENDAR_INVITESTATUS_NOT_SIGNEDUP = 8;
CALENDAR_INVITESTATUS_TENTATIVE = 9;
CALENDAR_MAX_INVITESTATUS = CALENDAR_INVITESTATUS_TENTATIVE;

-- Invite Types
CALENDAR_INVITETYPE_NORMAL = 1;
CALENDAR_INVITETYPE_SIGNUP = 2;
CALENDAR_MAX_INVITETYPE = CALENDAR_INVITETYPE_SIGNUP;

--
-- LFG
--
LFG_HIDDEN_GROUP_TYPE = 3;

--
-- Difficulty
--
QuestDifficultyColors = {
	["impossible"]    = CreateColor(1, 0.1, 0.1, 1),
	["verydifficult"] = CreateColor(1, 0.5, 0.25, 1),
	["difficult"]     = CreateColor(1, 1, 0, 1),
	["standard"]      = CreateColor(0.25, 0.75, 0.25, 1),
	["trivial"]       = CreateColor(0.5, 0.5, 0.5, 1),
	["header"]        = CreateColor(0.7, 0.7, 0.7, 1),
};

--
-- Rank Colors
--
LEADERBOARD_RANK_COLORS = {
	[1] = CreateColor(0.75, 0.87, 0.89),
	[2] = CreateColor(1, 0.82, 0),
	[3] = CreateColor(0.6, 0.6, 0.6),
	[4] = CreateColor(0.8, 0.5, 0.2),
}

LEADERBOARD_MEDAL_TEXTURES_SMALL = {
	[1] = "Interface\\Challenges\\challenges-plat-sm",
	[2] = "Interface\\Challenges\\challenges-gold-sm",
	[3] = "Interface\\Challenges\\challenges-silver-sm",
	[4] = "Interface\\Challenges\\challenges-bronze-sm",
}

--
-- Recipe Colors
--
RECIPE_COLORS = {
	Category       = CreateColor(1, 0.82, 0),
	Learnable      = CreateColor(0.1, 0.5, 0.1),
	Recipe         = CreateColor(0.3, 0.3, 0.1),
	HighRiskRecipe = CreateColor(0.4, 0.3, 0.1),
	Unlearned      = CreateColor(0.5, 0.1, 0.1),
	Unlearnable    = CreateColor(0.3, 0.3, 0.3),
	Always         = CreateColor(1, 0.5, 0.25),
	Often          = CreateColor(1, 1, 0),
	Seldom         = CreateColor(0.25, 0.75, 0.25),
	Never          = CreateColor(0.5, 0.5, 0.5),
	Unavailable    = CreateColor(0.8, 0.1, 0.1),
}
--
-- WorldMap
--
NUM_WORLDMAP_DETAIL_TILES = 12;
NUM_WORLDMAP_PATCH_TILES = 6;
NUM_WORLDMAP_DETAIL_TILE_ROWS = 3;
NUM_WORLDMAP_DETAIL_TILE_COLS = 4;

--
-- Totems
--

MAX_TOTEMS = 4;

FIRE_TOTEM_SLOT = 1;
EARTH_TOTEM_SLOT = 2;
WATER_TOTEM_SLOT = 3;
AIR_TOTEM_SLOT = 4;

TOTEM_PRIORITIES = {
	EARTH_TOTEM_SLOT,
	FIRE_TOTEM_SLOT,
	WATER_TOTEM_SLOT,
	AIR_TOTEM_SLOT,
};

TOTEM_MULTI_CAST_SUMMON_SPELLS = {
	66842,
	66843,
	66844,
};

TOTEM_MULTI_CAST_SUMMON_SPELLS_ALT = {
	1566842,
	1566843,
	1566844
}

TOTEM_MULTI_CAST_RECALL_SPELLS = {
	36936,
};

TOTEM_MULTI_CAST_RECALL_SPELLS_ALT = {
	1136936,
}
--
-- GM Ticket
--

GMTICKET_QUEUE_STATUS_ENABLED = 1;
GMTICKET_QUEUE_STATUS_DISABLED = -1;

GMTICKET_ASSIGNEDTOGM_STATUS_NOT_ASSIGNED = 0;    -- ticket is not currently assigned to a gm
GMTICKET_ASSIGNEDTOGM_STATUS_ASSIGNED = 1;        -- ticket is assigned to a normal gm
GMTICKET_ASSIGNEDTOGM_STATUS_ESCALATED = 2;        -- ticket is in the escalation queue

GMTICKET_OPENEDBYGM_STATUS_NOT_OPENED = 0;        -- ticket has never been opened by a gm
GMTICKET_OPENEDBYGM_STATUS_OPENED = 1;            -- ticket has been opened by a gm


-- indicies for adding lights ModelFFX:Add*Light
LIGHT_LIVE = 0;
LIGHT_GHOST = 1;

-- general constant translation table
STATIC_CONSTANTS = {}
RegisterStaticConstants(STATIC_CONSTANTS);

-- textures for quest item overlays
TEXTURE_ITEM_QUEST_BANG = "Interface\\ContainerFrame\\UI-Icon-QuestBang";
TEXTURE_ITEM_QUEST_BORDER = "Interface\\ContainerFrame\\UI-Icon-QuestBorder";

-- Friends
SHOW_SEARCH_BAR_NUM_FRIENDS = 12;

-- faction
PLAYER_FACTION_GROUP = { [0] = "Horde", [1] = "Alliance" };
function GetColoredReputationName(standingIndex)
	local standing = _G["FACTION_STANDING_LABEL"..standingIndex]
	if not standing then return RED_FONT_COLOR:WrapText(UNKNOWN) end
	
	local color = FACTION_STANDING_COLORS[standingIndex] or HIGHLIGHT_FONT_COLOR
	return color:WrapText(standing)
end

FACTION_BAR_COLORS = {
	[1] = CreateColor(0.8, 0.3, 0.22),
	[2] = CreateColor(0.8, 0.3, 0.22),
	[3] = CreateColor(0.75, 0.27, 0),
	[4] = CreateColor(0.9, 0.7, 0),
	[5] = CreateColor(0, 0.6, 0.1),
	[6] = CreateColor(0, 0.6, 0.1),
	[7] = CreateColor(0, 0.6, 0.1),
	[8] = CreateColor(0, 0.6, 0.1),
};

--
-- Custom Power Item Stats
--

PVE_POWER_CAP = 495
PVE_POWER_DAMAGE_MULTIPLIER = 0.05
PVE_POWER_DAMAGE_TAKEN_MULTIPLIER = 0.05
PVE_POWER_HEALING_MULTIPLIER = 0.02 

PVP_POWER_CAP = 495
PVP_POWER_DAMAGE_MULTIPLIER = 0.05
PVP_POWER_HEALING_MULTIPLIER = 0.02

ILVL_NUM_SLOTS = 15 -- How many slots count towards the ilvl threshold.
ILVL_INVALID_SLOTS = { -- Invalid slots for ilvl calculation
	[INVSLOT_BODY]    = true,
	[INVSLOT_TABARD]  = true,
	[INVSLOT_RANGED]  = true,
	[INVSLOT_OFFHAND] = true,
}
--
-- PVP
--
RATED_SIZE_STRINGS = { ARENA_2V2, ARENA_3V3, ARENA_1V1 }
RATED_TYPE_STRINGS = { ARENA_SOLO_QUEUE, ARENA_SOLO_QUEUE, ARENA_SOLO_QUEUE }
if IsDefaultClass("player") then
    RATED_SIZE_STRINGS[3] = ARENA_3V3
    RATED_TYPE_STRINGS[3] = ARENA_GROUP_QUEUE
end
PVP_RULESET_CHOICE_LEVEL = 20

HIGH_RISK_TIER_COLOR = {}

HIGH_RISK_TIER_COLOR[1] = CreateColor(0, 1, 0)
HIGH_RISK_TIER_COLOR[2] = CreateColor(1, 1, 0)
HIGH_RISK_TIER_COLOR[3] = CreateColor(1, 0, 0)

function GetHighRiskTierColor(tierID)
    if HIGH_RISK_TIER_COLOR[tierID] then
        return HIGH_RISK_TIER_COLOR[tierID]:GetRGBA()
    end

    return 1, 1, 1
end

--
-- Rulesets
--
RULESETS = {
	[Enum.Ruleset.NoRiskPvE]   = 84422,
	[Enum.Ruleset.NoRiskPvP]   = 84420,
	[Enum.Ruleset.HighRiskPvP] = 84421,
}

--
-- Mythic Plus
--
MYTHIC_PLUS_STATIC_AFFIXES = {
	{ -- health percent
		icon         = "Interface\\Icons\\Spell_Shadow_LifeDrain",
		name         = MYTHIC_PLUS_EXTRA_HEALTH_D,
		value        = "healthPercentage",
		tooltipTitle = MYTHIC_PLUS_EXTRA_HEALTH,
		tooltipText  = MYTHIC_PLUS_EXTRA_HEALTH_DESCRIPTION,
	},
	{ -- damage percent
		icon         = "Interface\\Icons\\inv_sword_11",
		name         = MYTHIC_PLUS_EXTRA_DAMAGE_D,
		value        = "physicalDamagePercentage",
		tooltipTitle = MYTHIC_PLUS_EXTRA_DAMAGE,
		tooltipText  = MYTHIC_PLUS_EXTRA_DAMAGE_DESCRIPTION,
	},
	{ -- spell damage percent
		icon         = "Interface\\Icons\\spell_shadow_shadowbolt",
		name         = MYTHIC_PLUS_EXTRA_MAGIC_DAMAGE_D,
		value        = "magicDamagePercentage",
		tooltipTitle = MYTHIC_PLUS_EXTRA_MAGIC_DAMAGE,
		tooltipText  = MYTHIC_PLUS_EXTRA_MAGIC_DAMAGE_DESCRIPTION,
	},
}

MYTHIC_PLUS_BONUS_LEVEL_PERCENT = {
	0.55,
	0.4,
}

--
-- Spellbook
--
BOOKTYPE_SPELL = "spell"
BOOKTYPE_PET = "pet"
BOOKTYPE_PROFESSION = "professions"
PRIMARY_PROFESSIONS = {
	Enum.Profession.Blacksmithing,
	Enum.Profession.Alchemy,
	Enum.Profession.Enchanting,
	Enum.Profession.Engineering,
	Enum.Profession.Jewelcrafting,
	Enum.Profession.Inscription,
	Enum.Profession.Leatherworking,
	Enum.Profession.Tailoring,
	Enum.Profession.Herbalism,
	Enum.Profession.Mining,
	Enum.Profession.Skinning,
}

SECONDARY_PROFESSIONS = {
	Enum.Profession.Cooking,
	Enum.Profession.FirstAid,
	Enum.Profession.Fishing,
	Enum.Profession.Bushcraft,
	Enum.Profession.Woodcutting,
}

--
-- High Risk
--
HIGH_RISK_GEAR_REQ_ILVL = {
	[Enum.GameEvent.VanillaHighRiskMaterials] = 40,
	[Enum.GameEvent.HighRiskZG]               = 60,
	[Enum.GameEvent.HighRiskMC]               = 63,
	[Enum.GameEvent.HighRiskONY]              = 64,
	[Enum.GameEvent.HighRiskBWL]              = 69,
	[Enum.GameEvent.HighRiskAQR]              = 69,
	[Enum.GameEvent.HighRiskAQT]              = 74,
	[Enum.GameEvent.HighRiskNAXX]             = 82,
}

HIGH_RISK_EVENT_MIN_ILVL = {
	[60] = 35,
	[70] = 111,
	[80] = 187, -- [PH]
}
--
-- Specs
--
SPEC_SWAP_SPELLS = {
	979993,
	979994,
	979995,
	979996,
	979997,
	979986,
	979987,
	979988,
	84874,
	84876,
	84878,
	84880,
	84882,
	84884,
	84886,
	84888,
	84890,
	84892,
	84894,
	84896
}

IS_SPEC_SWAP_SPELL = table.invert(SPEC_SWAP_SPELLS)

--
-- Mystic Enchanting
--

if IsDefaultClass() then
	NUM_MYSTIC_ENCHANT_SLOTS = 11
else
	NUM_MYSTIC_ENCHANT_SLOTS = 17
end
MAX_MYSTIC_ENCHANT_PRESETS = 100

PRESET_CHANGE_SPELLS = {
	84789, 84790, 84791, 84792, 84793, 84799, 84800, 84801, 84802, 84803, 85799, 85801, 85803, 85805, 85807, 85809, 85811, 85813, 85815, 85817, 85819, 85821, 85823, 85825, 85827, 85829, 85831, 85833,
	85835, 85837, 85839, 85841, 85843, 85845, 85847, 85849, 85851, 85853, 85855, 85857, 85859, 85861, 85863, 85865, 85867, 85869, 85871, 85873, 85875, 85877, 85879, 85881, 85883, 85885, 85887, 85889,
	85891, 85893, 85895, 85897, 85899, 85901, 85903, 85905, 85907, 85909, 85911, 85913, 85915, 85917, 85919, 85921, 85923, 85925, 85927, 85929, 85931, 85933, 85935, 85937, 85939, 85941, 85943, 85945,
	85947, 85949, 85951, 85953, 85955, 85957, 85959, 85961, 85963, 85965, 85967, 85969, 85971, 85973, 85975, 85977, 85979, 85981, 85983, 85985, 85987, 85989, 85991, 85993, 85995, 85997, 85999, 86002,
	86004, 86006, 86008, 86011, 86014, 86016, 86018, 86020, 86022, 86025, 86028, 86031, 86034, 86037, 86041, 86043, 86045, 86048, 86050, 86052, 86054, 86056, 86058, 86060, 86062, 86064, 86066, 86068,
	86070, 86072, 86074, 86077, 86079, 86081, 86083, 86085, 86087, 86090, 86092, 86094, 86096, 86098, 86100, 86102, 86104, 86108, 86111, 86113, 86116, 86120, 86122, 86124, 86127, 86129, 86132, 86135,
	86138, 86140, 86142, 86146, 86148, 86150, 86153, 86155, 86158, 86161, 86164, 86167, 86171, 86173, 86175, 86178, 86180, 86182, 86184, 86186, 86188, 86190, 86193, 86195, 86197, 86199, 86201, 86203,
	86205, 86207, 86209, 86211, 86213, 86215, 86217, 86220, 86222, 86224, 86226, 86228, 86230, 86232, 86234, 86238, 86241, 86243, 86249, 86251, 86253, 86256, 86259, 86262, 86265, 86268, 86271, 86276,
	86278, 86280, 86283, 86286, 86288, 86290, 86292, 86297, 86300, 86302, 86304, 86306, 86308, 86310, 86312, 86314, 86316, 86318, 86320, 86323, 86326, 86328, 86330, 86332, 86334, 86337, 86339, 86341,
	86343, 86345
}

PRESET_SAVE_SPELLS = {
	84804, 84812, 84813, 84814, 84815, 84816, 84817, 84818, 84819, 84820, 85800, 85802, 85804, 85806, 85808, 85810, 85812, 85814, 85816, 85818, 85820, 85822, 85824, 85826, 85828, 85830, 85832, 85834,
	85836, 85838, 85840, 85842, 85844, 85846, 85848, 85850, 85852, 85854, 85856, 85858, 85860, 85862, 85864, 85866, 85868, 85870, 85872, 85874, 85876, 85878, 85880, 85882, 85884, 85886, 85888, 85890,
	85892, 85894, 85896, 85898, 85900, 85902, 85904, 85906, 85908, 85910, 85912, 85914, 85916, 85918, 85920, 85922, 85924, 85926, 85928, 85930, 85932, 85934, 85936, 85938, 85940, 85942, 85944, 85946,
	85948, 85950, 85952, 85954, 85956, 85958, 85960, 85962, 85964, 85966, 85968, 85970, 85972, 85974, 85976, 85978, 85980, 85982, 85984, 85986, 85988, 85990, 85992, 85994, 85996, 85998, 86001, 86003,
	86005, 86007, 86009, 86013, 86015, 86017, 86019, 86021, 86023, 86026, 86030, 86033, 86035, 86038, 86042, 86044, 86046, 86049, 86051, 86053, 86055, 86057, 86059, 86061, 86063, 86065, 86067, 86069,
	86071, 86073, 86075, 86078, 86080, 86082, 86084, 86086, 86089, 86091, 86093, 86095, 86097, 86099, 86101, 86103, 86106, 86109, 86112, 86115, 86119, 86121, 86123, 86126, 86128, 86130, 86134, 86137,
	86139, 86141, 86145, 86147, 86149, 86152, 86154, 86156, 86160, 86163, 86165, 86168, 86172, 86174, 86176, 86179, 86181, 86183, 86185, 86187, 86189, 86191, 86194, 86196, 86198, 86200, 86202, 86204,
	86206, 86208, 86210, 86212, 86214, 86216, 86219, 86221, 86223, 86225, 86227, 86229, 86231, 86233, 86236, 86239, 86242, 86245, 86250, 86252, 86254, 86257, 86260, 86264, 86267, 86269, 86275, 86277,
	86279, 86282, 86285, 86287, 86289, 86291, 86293, 86299, 86301, 86303, 86305, 86307, 86309, 86311, 86313, 86315, 86317, 86319, 86321, 86325, 86327, 86329, 86331, 86333, 86335, 86338, 86340, 86342,
	86344, 86346
}

IS_PRESET_CHANGE_SPELL = {
	[84789] = true, [84790] = true, [84791] = true, [84792] = true, [84793] = true, [84799] = true, [84800] = true, [84801] = true, [84802] = true, [84803] = true, [85799] = true, [85801] = true, [85803] = true, [85805] = true, [85807] = true, [85809] = true, [85811] = true, [85813] = true, [85815] = true, [85817] = true, [85819] = true, [85821] = true, [85823] = true, [85825] = true, [85827] = true, [85829] = true, [85831] = true, [85833] = true,
	[85835] = true, [85837] = true, [85839] = true, [85841] = true, [85843] = true, [85845] = true, [85847] = true, [85849] = true, [85851] = true, [85853] = true, [85855] = true, [85857] = true, [85859] = true, [85861] = true, [85863] = true, [85865] = true, [85867] = true, [85869] = true, [85871] = true, [85873] = true, [85875] = true, [85877] = true, [85879] = true, [85881] = true, [85883] = true, [85885] = true, [85887] = true, [85889] = true,
	[85891] = true, [85893] = true, [85895] = true, [85897] = true, [85899] = true, [85901] = true, [85903] = true, [85905] = true, [85907] = true, [85909] = true, [85911] = true, [85913] = true, [85915] = true, [85917] = true, [85919] = true, [85921] = true, [85923] = true, [85925] = true, [85927] = true, [85929] = true, [85931] = true, [85933] = true, [85935] = true, [85937] = true, [85939] = true, [85941] = true, [85943] = true, [85945] = true,
	[85947] = true, [85949] = true, [85951] = true, [85953] = true, [85955] = true, [85957] = true, [85959] = true, [85961] = true, [85963] = true, [85965] = true, [85967] = true, [85969] = true, [85971] = true, [85973] = true, [85975] = true, [85977] = true, [85979] = true, [85981] = true, [85983] = true, [85985] = true, [85987] = true, [85989] = true, [85991] = true, [85993] = true, [85995] = true, [85997] = true, [85999] = true, [86002] = true,
	[86004] = true, [86006] = true, [86008] = true, [86011] = true, [86014] = true, [86016] = true, [86018] = true, [86020] = true, [86022] = true, [86025] = true, [86028] = true, [86031] = true, [86034] = true, [86037] = true, [86041] = true, [86043] = true, [86045] = true, [86048] = true, [86050] = true, [86052] = true, [86054] = true, [86056] = true, [86058] = true, [86060] = true, [86062] = true, [86064] = true, [86066] = true, [86068] = true,
	[86070] = true, [86072] = true, [86074] = true, [86077] = true, [86079] = true, [86081] = true, [86083] = true, [86085] = true, [86087] = true, [86090] = true, [86092] = true, [86094] = true, [86096] = true, [86098] = true, [86100] = true, [86102] = true, [86104] = true, [86108] = true, [86111] = true, [86113] = true, [86116] = true, [86120] = true, [86122] = true, [86124] = true, [86127] = true, [86129] = true, [86132] = true, [86135] = true,
	[86138] = true, [86140] = true, [86142] = true, [86146] = true, [86148] = true, [86150] = true, [86153] = true, [86155] = true, [86158] = true, [86161] = true, [86164] = true, [86167] = true, [86171] = true, [86173] = true, [86175] = true, [86178] = true, [86180] = true, [86182] = true, [86184] = true, [86186] = true, [86188] = true, [86190] = true, [86193] = true, [86195] = true, [86197] = true, [86199] = true, [86201] = true, [86203] = true,
	[86205] = true, [86207] = true, [86209] = true, [86211] = true, [86213] = true, [86215] = true, [86217] = true, [86220] = true, [86222] = true, [86224] = true, [86226] = true, [86228] = true, [86230] = true, [86232] = true, [86234] = true, [86238] = true, [86241] = true, [86243] = true, [86249] = true, [86251] = true, [86253] = true, [86256] = true, [86259] = true, [86262] = true, [86265] = true, [86268] = true, [86271] = true, [86276] = true,
	[86278] = true, [86280] = true, [86283] = true, [86286] = true, [86288] = true, [86290] = true, [86292] = true, [86297] = true, [86300] = true, [86302] = true, [86304] = true, [86306] = true, [86308] = true, [86310] = true, [86312] = true, [86314] = true, [86316] = true, [86318] = true, [86320] = true, [86323] = true, [86326] = true, [86328] = true, [86330] = true, [86332] = true, [86334] = true, [86337] = true, [86339] = true, [86341] = true,
	[86343] = true, [86345] = true,
}

IS_PRESET_SAVE_SPELL = {
	[84804] = true, [84812] = true, [84813] = true, [84814] = true, [84815] = true, [84816] = true, [84817] = true, [84818] = true, [84819] = true, [84820] = true, [85800] = true, [85802] = true, [85804] = true, [85806] = true, [85808] = true, [85810] = true, [85812] = true, [85814] = true, [85816] = true, [85818] = true, [85820] = true, [85822] = true, [85824] = true, [85826] = true, [85828] = true, [85830] = true, [85832] = true, [85834] = true,
	[85836] = true, [85838] = true, [85840] = true, [85842] = true, [85844] = true, [85846] = true, [85848] = true, [85850] = true, [85852] = true, [85854] = true, [85856] = true, [85858] = true, [85860] = true, [85862] = true, [85864] = true, [85866] = true, [85868] = true, [85870] = true, [85872] = true, [85874] = true, [85876] = true, [85878] = true, [85880] = true, [85882] = true, [85884] = true, [85886] = true, [85888] = true, [85890] = true,
	[85892] = true, [85894] = true, [85896] = true, [85898] = true, [85900] = true, [85902] = true, [85904] = true, [85906] = true, [85908] = true, [85910] = true, [85912] = true, [85914] = true, [85916] = true, [85918] = true, [85920] = true, [85922] = true, [85924] = true, [85926] = true, [85928] = true, [85930] = true, [85932] = true, [85934] = true, [85936] = true, [85938] = true, [85940] = true, [85942] = true, [85944] = true, [85946] = true,
	[85948] = true, [85950] = true, [85952] = true, [85954] = true, [85956] = true, [85958] = true, [85960] = true, [85962] = true, [85964] = true, [85966] = true, [85968] = true, [85970] = true, [85972] = true, [85974] = true, [85976] = true, [85978] = true, [85980] = true, [85982] = true, [85984] = true, [85986] = true, [85988] = true, [85990] = true, [85992] = true, [85994] = true, [85996] = true, [85998] = true, [86001] = true, [86003] = true,
	[86005] = true, [86007] = true, [86009] = true, [86013] = true, [86015] = true, [86017] = true, [86019] = true, [86021] = true, [86023] = true, [86026] = true, [86030] = true, [86033] = true, [86035] = true, [86038] = true, [86042] = true, [86044] = true, [86046] = true, [86049] = true, [86051] = true, [86053] = true, [86055] = true, [86057] = true, [86059] = true, [86061] = true, [86063] = true, [86065] = true, [86067] = true, [86069] = true,
	[86071] = true, [86073] = true, [86075] = true, [86078] = true, [86080] = true, [86082] = true, [86084] = true, [86086] = true, [86089] = true, [86091] = true, [86093] = true, [86095] = true, [86097] = true, [86099] = true, [86101] = true, [86103] = true, [86106] = true, [86109] = true, [86112] = true, [86115] = true, [86119] = true, [86121] = true, [86123] = true, [86126] = true, [86128] = true, [86130] = true, [86134] = true, [86137] = true,
	[86139] = true, [86141] = true, [86145] = true, [86147] = true, [86149] = true, [86152] = true, [86154] = true, [86156] = true, [86160] = true, [86163] = true, [86165] = true, [86168] = true, [86172] = true, [86174] = true, [86176] = true, [86179] = true, [86181] = true, [86183] = true, [86185] = true, [86187] = true, [86189] = true, [86191] = true, [86194] = true, [86196] = true, [86198] = true, [86200] = true, [86202] = true, [86204] = true,
	[86206] = true, [86208] = true, [86210] = true, [86212] = true, [86214] = true, [86216] = true, [86219] = true, [86221] = true, [86223] = true, [86225] = true, [86227] = true, [86229] = true, [86231] = true, [86233] = true, [86236] = true, [86239] = true, [86242] = true, [86245] = true, [86250] = true, [86252] = true, [86254] = true, [86257] = true, [86260] = true, [86264] = true, [86267] = true, [86269] = true, [86275] = true, [86277] = true,
	[86279] = true, [86282] = true, [86285] = true, [86287] = true, [86289] = true, [86291] = true, [86293] = true, [86299] = true, [86301] = true, [86303] = true, [86305] = true, [86307] = true, [86309] = true, [86311] = true, [86313] = true, [86315] = true, [86317] = true, [86319] = true, [86321] = true, [86325] = true, [86327] = true, [86329] = true, [86331] = true, [86333] = true, [86335] = true, [86338] = true, [86340] = true, [86342] = true,
	[86344] = true, [86346] = true,
}

--
-- Raid 
--
NUM_WORLD_RAID_MARKERS = 8
NUM_RAID_ICONS = 8

WORLD_RAID_MARKER_ORDER = {}
WORLD_RAID_MARKER_ORDER[1] = 8
WORLD_RAID_MARKER_ORDER[2] = 4
WORLD_RAID_MARKER_ORDER[3] = 1
WORLD_RAID_MARKER_ORDER[4] = 7
WORLD_RAID_MARKER_ORDER[5] = 2
WORLD_RAID_MARKER_ORDER[6] = 3
WORLD_RAID_MARKER_ORDER[7] = 6
WORLD_RAID_MARKER_ORDER[8] = 5

MINIMUM_RAID_CONTAINER_HEIGHT = 72
MEMBERS_PER_RAID_GROUP = 5

--
-- CoA Multicast spells
--
NECROMANCER_SUMMON_ALL_MINIONS_SPELL_ID = 505550 -- Summon All Minions (long cast)
NECROMANCER_SUMMON_SPELLS = {
    -- 1 Life Force Cost
    500332, -- Raise: Skeletal Archer
    500969, -- Raise: Skeletal Rogue / Putrid Geist
    500971, -- Raise: Ghoul
    500970, -- Raise: Skeletal Warrior

    -- 2 Life Force Cost
    500331, -- Raise: Skeletal Mage (1 with Champion of Kel'Thuzad)
    504901, -- Raise: Greater Skeletal Warrior
    504859, -- Raise: Crypt Fiend
    504861, -- Raise: Ghost

    -- 3 Life Force Cost
    500335, -- Raise: Abomination
    500329, -- Raise: Revenant (Gargoyle)
    500989, -- Raise: Unholy/Decaying Colossus
};

-- 
-- CoA Totem Remap
--
COA_TOTEM_NAME_REMAP = {
    -- Idols (Water)
    [507082] = COA_TOTEM_IDOL,     -- Frenzy Idol
    [500961] = COA_TOTEM_IDOL,     -- Spirit Idol
    [706369] = COA_TOTEM_IDOL,     -- Spirit Link Idol
    [504759] = COA_TOTEM_IDOL,     -- Wuju Idol
    [804226] = COA_TOTEM_IDOL,     -- Swift Idol
    [504840] = COA_TOTEM_IDOL,     -- Cleansing Idol

    -- Effigies (Earth)
    [505339] = COA_TOTEM_EFFIGY,   -- Shadow Effigy
    [506634] = COA_TOTEM_EFFIGY,   -- Hexing Effigy
    [506635] = COA_TOTEM_EFFIGY,   -- Graven Effigy
    [706542] = COA_TOTEM_EFFIGY,   -- Cursed Effigy

    -- Wards (Fire)
    [801678] = COA_TOTEM_WARD,     -- Stasis Ward
    [500957] = COA_TOTEM_WARD,     -- Healing Ward
    [500960] = COA_TOTEM_WARD,     -- Serpent Ward
    [500013] = COA_TOTEM_WARD,     -- Voodoo Ward
    [674303] = COA_TOTEM_WARD,     -- Sentry Ward
	[707162] = COA_TOTEM_WARD,     -- Mimic Ward

    -- Standards (Guardian)
    [500547] = STANDARD,
    [500263] = STANDARD,
    [500260] = STANDARD,
    [500299] = STANDARD,
    [706805] = STANDARD,
    [800319] = STANDARD,
    [803931] = STANDARD,
    [803932] = STANDARD,
    [803933] = STANDARD,
    [803934] = STANDARD,
    [803935] = STANDARD,
    [803936] = STANDARD,
    [803937] = STANDARD,
    [803938] = STANDARD,
}

--
-- Debug
--
JSON_BENCHMARKS = {
	color  = CreateColor(1, 1, 1, 1),
	totals = {}
}

function JSON_BENCHMARKS:Time(phase, key)
	self[phase] = self[phase] or {}

	if self[phase][key] then
		self[phase][key] = GetTime() - (self[phase][key])
		if not phase:endswith("-async") then
			self.totals[key] = self[phase][key] + (self.totals[key] or 0)
		end
	else
		self[phase][key] = GetTime()
	end
end

function JSON_BENCHMARKS:PrintTable(name, minV, maxV, values)
	table.sort(values, function(a, b)
		return a[2] < b[2]
	end)

	local total = 0

	print("[|cff00FF00" .. name .. "|r]")
	for _, data in pairs(values) do
		total = total + data[2]
		local t = math.RemapToRange(data[2], minV, maxV, 0, 1)
		ColorUtil:Lerp(GREEN_FONT_COLOR, RED_FONT_COLOR, t, self.color)

		local value = self.color:WrapText(format("%.3f", data[2]))

		print("[|cffFFD100" .. data[1] .. "|r] = " .. value)
	end
	print("[|cff00FF00Total|r]", format("= %.3f", total))
end

function JSON_BENCHMARKS:PrintLoads()
	if not self["load"] then
		SendSystemMessage("No Load Data")
		return
	end

	local minV, maxV
	local values = {}

	for file, v in pairs(self["load"]) do
		if not minV or v < minV then
			minV = v
		end

		if not maxV or v > maxV then
			maxV = v
		end
		tinsert(values, { file, v })
	end

	self:PrintTable("JSON Load Times", minV, maxV, values)
end

function JSON_BENCHMARKS:PrintDecode()
	if not self["decode"] then
		SendSystemMessage("No Decode Data")
		return
	end

	local minV, maxV
	local values = {}

	for file, v in pairs(self["decode"]) do
		if not minV or v < minV then
			minV = v
		end

		if not maxV or v > maxV then
			maxV = v
		end
		tinsert(values, { file, v })
	end

	self:PrintTable("JSON Decode Times", minV, maxV, values)
end

function JSON_BENCHMARKS:PrintParses()
	if not self["parse"] then
		SendSystemMessage("No Parse Data")
		return
	end

	local minV, maxV
	local values = {}

	for file, v in pairs(self["parse"]) do
		if not minV or v < minV then
			minV = v
		end

		if not maxV or v > maxV then
			maxV = v
		end
		tinsert(values, { file, v })
	end

	self:PrintTable("JSON Parse Times", minV, maxV, values)
end

function JSON_BENCHMARKS:PrintAsyncParses()
	if not self["parse-async"] then
		SendSystemMessage("No Async Parse Data")
		return
	end

	local minV, maxV
	local values = {}

	for file, v in pairs(self["parse-async"]) do
		if not minV or v < minV then
			minV = v
		end

		if not maxV or v > maxV then
			maxV = v
		end
		tinsert(values, { file, v })
	end

	self:PrintTable("JSON Async Parse Times", minV, maxV, values)
end

function JSON_BENCHMARKS:PrintTotals()
	local minV, maxV
	local values = {}

	for file, v in pairs(self.totals) do
		if not minV or v < minV then
			minV = v
		end

		if not maxV or v > maxV then
			maxV = v
		end
		tinsert(values, { file, v })
	end

	self:PrintTable("JSON Total Times", minV, maxV, values)
end

function JSON_BENCHMARKS:Print(msg)
	msg = msg and msg:lower()
	if msg == "" then
		self:PrintLoads()
		self:PrintDecode()
		self:PrintParses()
		self:PrintAsyncParses()
		self:PrintTotals()
	elseif msg == "load" or msg == "loads" then
		self:PrintLoads()
	elseif msg == "decode" then
		self:PrintDecode()
	elseif msg == "parse" then
		self:PrintParses()
	elseif msg == "parses" then
		self:PrintParses()
		self:PrintAsyncParses()
	elseif msg == "parse-async" then
		self:PrintAsyncParses()
	elseif msg == "async" then
		self:PrintAsyncParses()
	elseif msg == "total" or msg == "totals" then
		self:PrintTotals()
	end
end

_DecodeJSONContent = _DecodeJSONContent or DecodeJSONContent
function DecodeJSONContent(file)
	JSON_BENCHMARKS:Time("decode", file)
	local t = _DecodeJSONContent(file)
	JSON_BENCHMARKS:Time("decode", file)
	return t
end
