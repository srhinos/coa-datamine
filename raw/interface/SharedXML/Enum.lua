EnumUtil = {}

function EnumUtil.MakeEnum(...)
	return tinvert({ ... })
end

function EnumUtil.MakeMask(...)
	local enum = {}

	for i = 1, select("#", ...) do
		enum[select(i, ...)] = bit.lshift(1, i - 1)
	end

	return enum
end

function EnumUtil.CombineMasks(...)
	local value = 0
	for i = 1, select("#", ...) do
		value = bit.bor(value, select(i, ...))
	end

	return value
end

function EnumUtil.ValueToString(enum, enumValue)
	for key, value in pairs(enum) do
		if value == enumValue then
			return key
		end
	end
end

Enum = {}

--
-- Expansions
--
Enum.Expansion = {
	Vanilla = 0,
	TBC     = 1,
	WoTLK   = 2,
}

--
-- Classes
--
Enum.Class = {
	WARRIOR      = 1,
	PALADIN      = 2,
	HUNTER       = 3,
	ROGUE        = 4,
	PRIEST       = 5,
	DEATHKNIGHT  = 6,
	SHAMAN       = 7,
	MAGE         = 8,
	WARLOCK      = 9,
	HERO         = 10,
	DRUID        = 11,
	BARBARIAN    = 12,
	WITCHDOCTOR  = 13,
	DEMONHUNTER  = 14,
	WITCHHUNTER  = 15,
	STORMBRINGER = 16,
	FLESHWARDEN  = 17,
	GUARDIAN     = 18,
	MONK         = 19,
	SONOFARUGAL  = 20,
	RANGER       = 21,
	CHRONOMANCER = 22,
	NECROMANCER  = 23,
	PYROMANCER   = 24,
	CULTIST      = 25,
	STARCALLER   = 26,
	SUNCLERIC    = 27,
	TINKER       = 28,
	PROPHET      = 29,
	REAPER       = 30,
	WILDWALKER   = 31,
	SPIRITMAGE   = 32,
}

Enum.ClassFile = tinvert(Enum.Class)
Enum.Class.CustomStart = 12

Enum.ClassMask = {
	WARRIOR      = 0x1,
	PALADIN      = 0x2,
	HUNTER       = 0x4,
	ROGUE        = 0x8,
	PRIEST       = 0x10,
	DEATHKNIGHT  = 0x20,
	SHAMAN       = 0x40,
	MAGE         = 0x80,
	WARLOCK      = 0x100,
	HERO         = 0x200,
	DRUID        = 0x400,
	DEFAULT      = 0x5FF,
	BARBARIAN    = 0x800,
	WITCHDOCTOR  = 0x1000,
	DEMONHUNTER  = 0x2000,
	WITCHHUNTER  = 0x4000,
	STORMBRINGER = 0x8000,
	FLESHWARDEN  = 0x10000,
	GUARDIAN     = 0x20000,
	MONK         = 0x40000,
	SONOFARUGAL  = 0x80000,
	RANGER       = 0x100000,
	CHRONOMANCER = 0x200000,
	NECROMANCER  = 0x400000,
	PYROMANCER   = 0x800000,
	CULTIST      = 0x1000000,
	STARCALLER   = 0x2000000,
	SUNCLERIC    = 0x4000000,
	TINKER       = 0x8000000,
	PROPHET      = 0x10000000,
	REAPER       = 0x20000000,
	WILDWALKER   = 0x40000000,
	SPIRITMAGE   = 0x80000000,
	COA          = 0xFFFFF800,
}

Enum.Race = {
	Human    = 1,
	Orc      = 2,
	Dwarf    = 3,
	NightElf = 4,
	Scourge  = 5,
	Undead   = 5,
	Tauren   = 6,
	Gnome    = 7,
	Troll    = 8,
	BloodElf = 10,
	Draenei  = 11
}
Enum.RaceFile = tinvert(Enum.Race)

Enum.Sex = {
	None   = 1,
	Male   = 2,
	Female = 3,
}
--
-- Items
--
Enum.ItemQuality = {
	Poor      = 0,
	Common    = 1,
	Uncommon  = 2,
	Rare      = 3,
	Epic      = 4,
	Legendary = 5,
	Artifact  = 6,
	Vanity    = 6,
	Heirloom  = 7,
}

Enum.SpellQuality = {
	Poor      = 0,
	Common    = 1,
	Normal    = 1,
	Uncommon  = 2,
	Green     = 2,
	Rare      = 3,
	Blue      = 3,
	Epic      = 4,
	Purple    = 4,
	Legendary = 5,
	Orange    = 5,
	Artifact  = 6,
	Vanity    = 6,
	Heirloom  = 7,
}

Enum.QualityToCAQuality = {
	[0] = "Poor",
	[1] = "Common",
	[2] = "Uncommon",
	[3] = "Rare",
	[4] = "Epic",
	[5] = "Legendary",
	[6] = "Vanity",
	[7] = "Heirloom",
}

Enum.InventoryTypeMask = {
	NonEquip        = 0x1,
	Head            = 0x2,
	Necklace        = 0x4,
	Shoulders       = 0x8,
	Body            = 0x10,
	Chest           = 0x20,
	Waist           = 0x40,
	Legs            = 0x80,
	Feet            = 0x100,
	Wrists          = 0x200,
	Hands           = 0x400,
	Finger          = 0x800,
	Trinket         = 0x1000,
	Weapon          = 0x2000,
	Shield          = 0x4000,
	Ranged          = 0x8000,
	Cloak           = 0x10000,
	TwoHandedWeapon = 0x20000,
	Bag             = 0x40000,
	Tabard          = 0x80000,
	Robe            = 0x100000,
	MainHand        = 0x200000,
	OffHand         = 0x400000,
	Holdable        = 0x800000,
	Ammo            = 0x1000000,
	Thrown          = 0x2000000,
	RangedRight     = 0x4000000,
	Quiver          = 0x8000000,
	Relic           = 0x10000000,
}

-- class is 7th bit. bit.bor(byte.lshift(class, 6), mask) will get this value
Enum.EquippedItemClass = {
	Bag               = 0x1000001,
	SoulBag           = 0x1000002,
	HerbBag           = 0x1000004,
	EnchantingBag     = 0x1000008,
	EngineeringBag    = 0x1000010,
	GemBag            = 0x1000020,
	MiningBag         = 0x1000040,
	LeatherworkingBag = 0x1000080,
	InscriptionBag    = 0x1000100,
	Axe1H             = 0x2000001,
	Axe2H             = 0x2000002,
	Bow               = 0x2000004,
	Gun               = 0x2000008,
	Mace1H            = 0x2000010,
	Mace2H            = 0x2000020,
	Polearm           = 0x2000040,
	Sword1H           = 0x2000080,
	Sword2H           = 0x2000100,
	Obsolete          = 0x2000200,
	Staff             = 0x2000400,
	--Exotic1H          = 0x2000800,
	--Exotic2H          = 0x2001000,
	Fist              = 0x2002000,
	Misc              = 0x2004000,
	Dagger            = 0x2008000,
	Thrown            = 0x2010000,
	Spear             = 0x2020000,
	Crossbow          = 0x2040000,
	Wand              = 0x2080000,
	FishingPole       = 0x2100000,
	Red               = 0x3000001,
	Blue              = 0x3000002,
	Yellow            = 0x3000004,
	Purple            = 0x3000008,
	Green             = 0x3000010,
	Orange            = 0x3000020,
	Meta              = 0x3000040,
	Simple            = 0x3000080,
	Prismatic         = 0x3000100,
	Misc              = 0x4000001,
	Cloth             = 0x4000002,
	Leather           = 0x4000004,
	Mail              = 0x4000008,
	Plate             = 0x4000010,
	Buckler           = 0x4000020,
	Shield            = 0x4000040,
	Libram            = 0x4000080,
	Idol              = 0x4000100,
	Totem             = 0x4000200,
	Sigil             = 0x4000400,
}

--
-- Character Advancement
--
Enum.ResetCreditType = {
	AbilityReset   = 1,
	TalentReset    = 2,
	AbilityUnlearn = 3,
	TalentUnlearn  = 4,
}

Enum.PrimaryStat = {
	Strength  = 1,
	Agility   = 2,
	Intellect = 3,
	Spirit    = 4,
	Stamina   = 5,
	Duality   = 6,
	STAT_STRENGTH  = 1,
	STAT_AGILITY   = 2,
	STAT_INTELLECT = 3,
	STAT_SPIRIT    = 4,
	STAT_STAMINA   = 5,
	STAT_DUALITY   = 6,
}

Enum.CharacterAdvancementFlag = {
	None                 = 0x0,
	Deprecated           = 0x1,
	UnaffectedByResets   = 0x2,
	CannotBeUnlearned    = 0x4,
	Disabled             = 0x8,
	ConnectingNode       = 0x100,
	HiddenClientside     = 0x800,
	Mastery              = 0x1000,
	FreeUnlearn          = 0x2000,
	RequireAnyInvestment = 0x4000,
	ShowCardOnLearn      = 0x8000,
}

Enum.CharacterAdvancementType = {
	Ability = "Ability",
	Talent = "Talent",
	Trait = "Trait",
}

Enum.CALearnResult = {
	Ok = "CA_LEARN_OK",
	Unknown = "CA_LEARN_UNKNOWN",
	NotInWorld = "CA_LEARN_NOT_IN_WORLD",
	NotEnabled = "CA_LEARN_NOT_ENABLED",
	BadAbility = "CA_LEARN_BAD_ABILITY",
	BadGameMode = "CA_LEARN_BAD_GAME_MODE",
	LowLevel = "CA_LEARN_LOW_LEVEL",
	AlreadyKnown = "CA_LEARN_ALREADY_KNOWN",
	ConditionsFailed = "CA_LEARN_CONDITIONS_FAILED",
	NotInBattleground = "CA_LEARN_NOT_IN_BATTLEGROUNDS",
	WrongExpansion = "CA_LEARN_WRONG_EXPANSION",
	Disabled = "CA_LEARN_DISABLED",
	WrongClass = "CA_LEARN_WRONG_CLASS",
	StartingNodeAlreadyKnown = "CA_LEARN_ALREADY_KNOW_A_STARTING_NODE",
	MissingConnection = "CA_LEARN_MISSING_CONNECTED_ENTRIES",
	MinAbilityEssenceInvestment = "CA_LEARN_NOT_ENOUGH_INVESTED_AE",
	MinTalentEssenceInvestment = "CA_LEARN_NOT_ENOUGH_INVESTED_TE",
	MissingRequiredID = "CA_LEARN_MISSING_REQUIRED_ID",
	WrongRealm = "CA_LEARN_WRONG_REALM",
	NotInCombat = "CA_LEARN_NOT_IN_COMBAT",
	Deprecated = "CA_LEARN_DEPRECATED",
	NoBuildDraft = "CA_LEARN_BUILD_DRAFT",
	Invulnerable = "CA_LEARN_INVULNERABILE",
	NoTalentsChallenge = "CA_LEARN_NO_TALENTS_CHALLENGE",
	MaxUncommon = "CA_LEARN_TOO_MANY_UNCOMMON_ABILITIES",
	MaxRare = "CA_LEARN_TOO_MANY_RARE_ABILITIES",
	MaxEpic = "CA_LEARN_TOO_MANY_EPIC_ABILITIES",
	MaxLegendary = "CA_LEARN_TOO_MANY_LEGENDARY_ABILITIES",
	NoAbilityEssence = "CA_LEARN_MISSING_AE",
	NoTalentEssence = "CA_LEARN_MISSING_TE",
	WildCardTame = "CA_LEARN_WILDCARD_TAME_SPELLS",
	WildCardMasteries = "CA_LEARN_WILDCARD_MASTERIES",
	WildCardDisabled = "CA_LEARN_WILDCARD_DISABLED",
	WildCardLowLevel = "CA_LEARN_WILDCARD_LOW_LEVEL",
	WildCardStarterProtection = "CA_LEARN_WILDCARD_STARTER_REPEAT_PROTECTION",
	NoDead = "CA_LEARN_NOT_WHILE_DEAD",
	NoWildCard = "CA_LEARN_NOT_WILDCARD",
	NoDraft = "CA_LEARN_NOT_DRAFT",
	DisplayEntry = "CA_LEARN_DISPLAY_ENTRY",
}

Enum.CAUnlearnResult = {
  	Ok = "CA_UNLEARN_OK",
  	Unknown = "CA_UNLEARN_UNKNOWN",
  	NotInWorld = "CA_UNLEARN_NOT_IN_WORLD",
  	NotEnabled = "CA_UNLEARN_NOT_ENABLED",
  	BadAbility = "CA_UNLEARN_BAD_ABILITY",
  	NotInBattleground = "CA_UNLEARN_NOT_IN_BATTLEGROUNDS",
  	BadGameMode = "CA_UNLEARN_BAD_GAME_MODE",
  	NotThisAbility = "CA_UNLEARN_NOT_THIS_ABILITY",
  	NotInCombat = "CA_UNLEARN_NOT_IN_COMBAT",
  	NotKnown = "CA_UNLEARN_NOT_KNOWN",
  	NotEnoughCurrency = "CA_UNLEARN_NO_UNLEARN_ITEM",
  	MissingConnection = "CA_UNLEARN_MISSING_CONNECTED_ENTRIES",
  	MasteryID = "CA_UNLEARN_MASTERY_ID",
  	MissingRequiredID = "CA_UNLEARN_MISSING_REQUIRED_ID",
	MinAbilityEssenceInvestment = "CA_UNLEARN_NOT_ENOUGH_INVESTED_AE",
	MinTalentEssenceInvestment = "CA_UNLEARN_NOT_ENOUGH_INVESTED_TE",
  	NoScrollOfFortune = "CA_UNLEARN_NO_SCROLL_OF_FORTUNE",
  	Locked = "CA_UNLEARN_LOCKED",
  	NoWildCard = "CA_UNLEARN_NOT_WILDCARD",
	NoDraft = "CA_UNLEARN_NOT_DRAFT",
	WildCardSpendAE = "CA_UNLEARN_WILDCARD_UNSPENT_AE",
	WildCardSpendTE = "CA_UNLEARN_WILDCARD_UNSPENT_TE",
	ScrollOfFortuneLimit = "CA_UNLEARN_SCROLL_OF_FORTUNE_LIMIT",
}

Enum.CAConfirmReason = {
	Ok = "CA_CONFIRM_OK",
	Unknown = "CA_CONFIRM_UNKNOWN",
	IncludesMastery = "CA_CONFIRM_LEARN_INCLUDES_MASTERY",
	RemovesMastery = "CA_CONFIRM_UNLEARN_REMOVES_MASTERY",
	Marks = "CA_CONFIRM_UNLEARN_MARKS",
	Gold = "CA_CONFIRM_UNLEARN_GOLD",
	Token = "CA_CONFIRM_UNLEARN_TOKEN",
	AllTalentsToken = "CA_CONFIRM_UNLEARN_ALL_TALENTS_TOKEN",
	AllTalentsGold = "CA_CONFIRM_UNLEARN_ALL_TALENTS_GOLD",
	AllTalentsMarks = "CA_CONFIRM_UNLEARN_ALL_TALENTS_MARKS",
	AllTalentsDeactivateBuild = "CA_CONFIRM_UNLEARN_ALL_TALENTS_DEACTIVATE_BUILD",
	AllAbilitiesToken = "CA_CONFIRM_UNLEARN_ALL_ABILITIES_TOKEN",
	AllAbilitiesGold = "CA_CONFIRM_UNLEARN_ALL_ABILITIES_GOLD",
	AllAbilitiesMarks = "CA_CONFIRM_UNLEARN_ALL_ABILITIES_MARKS",
	AllAbilitiesDeactivateBuild = "CA_CONFIRM_UNLEARN_ALL_ABILITIES_DEACTIVATE_BUILD",
}

--
-- Misc
--
Enum.Comparisons = {
	Equal              = function(a, b) return a == b end,
	LessThan           = function(a, b) return a < b end,
	GreaterThan        = function(a, b) return a > b end,
	EqualOrLessThan    = function(a, b) return a <= b end,
	EqualOrGreaterThan = function(a, b) return a >= b end,
	NotEqual           = function(a, b) return a ~= b end,
}

--
-- PvP
--
Enum.Ruleset = {
	None        = 0,
	NoRiskPvE   = 1,
	NoRiskPvP   = 2,
	HighRiskPvP = 3,
}

--
-- High Risk Tiers
--
Enum.HighRiskZones = {
	TerokkarForest      = true,
	ShattrathCity       = true,
	Zangarmarsh         = true,
	Nagrand             = true,
	UngoroCrater        = true,
	Aszhara             = true, -- this typo is intentional.
	BurningSteppes      = true,
	BoreanTundra        = true,
	HowlingFjord        = true,
	CrystalsongForest   = true,

	BladesEdgeMountains = true,
	ShadowmoonValley    = true,
	EasternPlaguelands  = true,
	WesternPlaguelands  = true,
	LakeWintergrasp     = true,
	Dragonblight        = true,
	ZulDrak             = true,
	GrizzlyHills        = true,
    BlastedLands        = true,

	Silithus            = true,
	Winterspring        = true,
	Netherstorm         = true,
	TheStormPeaks       = true,
	IcecrownGlacier     = true,
	HrothgarsLanding    = true,
}

Enum.HighRiskZoneTiers = {
    TerokkarForest      = 1,
    ShattrathCity       = 1,
    Zangarmarsh         = 1,
    Nagrand             = 1,
    UngoroCrater        = 1,
    Aszhara             = 1, -- this typo is intentional.
    BurningSteppes      = 1,
    BoreanTundra        = 1,
    HowlingFjord        = 1,
    CrystalsongForest   = 1,

    BladesEdgeMountains = 2,
    ShadowmoonValley    = 2,
    EasternPlaguelands  = 2,
    WesternPlaguelands  = 2,
    LakeWintergrasp     = 2,
    Dragonblight        = 2,
    ZulDrak             = 2,
    GrizzlyHills        = 2,

    Silithus            = 3,
    Winterspring        = 3,
    Netherstorm         = 3,
    TheStormPeaks       = 3,
    IcecrownGlacier     = 3,
    HrothgarsLanding    = 3,
}

--
-- Roles
--
Enum.LFGRoles = {
	None    = 0x00,
	Leader  = 0x01,
	Tank    = 0x02,
	Healer  = 0x04,
	Damager = 0x08,
	Any     = 15,
}
--
-- Build Creator
--
Enum.BuildCreator = {}

Enum.BuildCategory = {
	ActiveBuild   = "ActiveBuild",
	Featured      = "Featured",
	None          = "None",
	MyBuilds      = "MyBuilds",
	Leveling      = "Leveling",
	Level60PvE    = "Level60PvE",
	Level60PvP    = "Level60PvP",
	Level60PvPvE  = "Level60PvPvE",
	Level70PvE    = "Level70PvE",
	Level70PvP    = "Level70PvP",
	Level70PvPvE  = "Level70PvPvE",
	BuildDraft    = "BuildDraft",
	Archived      = "Archived",
	BuildDraftEndGamePvE = "BuildDraftEndGamePvE",
	BuildDraftEndGamePvP = "BuildDraftEndGamePvP",
	History = "History",
}

Enum.BuildCreateCategory = {
	Import = "Import",
	CurrentBuild = "CurrentBuild",
	SavedBuild = "SavedBuild",
	Leveling = "Leveling",
	BuildDraft = "BuildDraft",
	Level60PvE = "Level60PvE",
	Level60PvP = "Level60PvP",
	Level70PvE = "Level70PvE",
	Level70PvP = "Level70PvP",
	BuildDraftEndGamePvE = "BuildDraftEndGamePvE",
	BuildDraftEndGamePvP = "BuildDraftEndGamePvP",
}

Enum.BuildSubCategory = {
	Level60PvE = "Level60PvPvE",
	Level60PvP = "Level60PvPvE",
	Level70PvE = "Level70PvPvE",
	Level70PvP = "Level70PvPvE",
	BuildDraftEndGamePvE = "BuildDraft",
	BuildDraftEndGamePvP = "BuildDraft",
}

Enum.BuildRoles = {
	PLAYER_ROLE_LEADER = "LEADER",
	PLAYER_ROLE_TANK   = "TANK",
	PLAYER_ROLE_HEALER = "HEALER",
	PLAYER_ROLE_DAMAGE = "DAMAGER",
	PLAYER_ROLE_ANY    = "DAMAGER",
}

Enum.BuildSort = {
	Default = "SORT_NONE",
	RatingAscending = "SORT_RATING_ASCENDING",
	RatingDescending = "SORT_RATING_DESCENDING",
	DateAscending = "SORT_DATE_ASCENDING",
	DateDescending = "SORT_DATE_DESCENDING",
}

Enum.WeaponSubClassSID = {
	ITEM_SUBCLASS_WEAPON_AXE = 196,
	ITEM_SUBCLASS_WEAPON_AXE2 = 197,
	ITEM_SUBCLASS_WEAPON_BOW = 264,
	ITEM_SUBCLASS_WEAPON_GUN = 266,
	ITEM_SUBCLASS_WEAPON_MACE = 198,
	ITEM_SUBCLASS_WEAPON_MACE2 = 199,
	ITEM_SUBCLASS_WEAPON_POLEARM = 200,
	ITEM_SUBCLASS_WEAPON_SWORD = 201,
	ITEM_SUBCLASS_WEAPON_SWORD2 = 202,
	ITEM_SUBCLASS_WEAPON_STAFF = 227,
	ITEM_SUBCLASS_WEAPON_FIST = 15590,
	ITEM_SUBCLASS_WEAPON_DAGGER = 1180,
	ITEM_SUBCLASS_WEAPON_THROWN = 2567,
	ITEM_SUBCLASS_WEAPON_CROSSBOW = 5011,
	ITEM_SUBCLASS_WEAPON_WAND = 5009,
}

Enum.WeaponSIDSubClass = tinvert(Enum.WeaponSubClassSID)

Enum.ArmorSubClassSID = {
	ITEM_SUBCLASS_ARMOR_CLOTH = 9078,
	ITEM_SUBCLASS_ARMOR_LEATHER = 9077,
	ITEM_SUBCLASS_ARMOR_MAIL = 8737,
	ITEM_SUBCLASS_ARMOR_PLATE = 750,
	ITEM_SUBCLASS_ARMOR_SHIELD = 9116,
	ITEM_SUBCLASS_ARMOR_LIBRAM = 27762,
	ITEM_SUBCLASS_ARMOR_IDOL = 27764,
	ITEM_SUBCLASS_ARMOR_TOTEM = 27763,
	ITEM_SUBCLASS_ARMOR_SIGIL = 52665, 
}

Enum.ArmorSIDSubClass = tinvert(Enum.ArmorSubClassSID)

Enum.BuildSpellFlags = {
	NotifyOnLearn = 0x1,
}

Enum.BuildDifficulty = {
	Standard     = "BUILD_DIFFICULTY_RATING_EASY",
	Intermediate = "BUILD_DIFFICULTY_RATING_NORMAL",
	Advanced     = "BUILD_DIFFICULTY_RATING_HARD",
	Expert       = "BUILD_DIFFICULTY_RATING_VERY_HARD",
	Impossible   = "BUILD_DIFFICULTY_RATING_IMPOSSIBLE",
}

Enum.BuildFilter = {
	Featured = "FILTER_FEATURED",
	Owned = "FILTER_OWNED_BUILDS",
	Recent = "FILTER_LAST_30_DAYS",

	-- difficulty
	Standard = "FILTER_DIFFICULTY_RATING_EASY",
	Intermediate = "FILTER_DIFFICULTY_RATING_NORMAL",
	Advanced = "FILTER_DIFFICULTY_RATING_HARD",
	Expert = "FILTER_DIFFICULTY_RATING_VERY_HARD",
	Impossible = "FILTER_DIFFICULTY_RATING_IMPOSSIBLE",
	
	-- primary stat
	Strength = "FILTER_PRIMARY_STAT_STRENGTH",
	Agility = "FILTER_PRIMARY_STAT_AGILITY",
	Intellect = "FILTER_PRIMARY_STAT_INTELLECT",
	Spirit = "FILTER_PRIMARY_STAT_SPIRIT",
	
	-- role
	Tank = "FILTER_ROLE_TANK",
	Healer = "FILTER_ROLE_HEALER",
	Damage = "FILTER_ROLE_DAMAGE",
}

Enum.BuildCreator.WeaponSubClass = {
	AXE          = 0,
	AXE2         = 1,
	BOW          = 2,
	GUN          = 3,
	MACE         = 4,
	MACE2        = 5,
	POLEARM      = 6,
	SWORD        = 7,
	SWORD2       = 8,
	obsolete     = 9,
	STAFF        = 10,
	EXOTIC       = 11,
	EXOTIC2      = 12,
	FIST         = 13,
	MISC         = 14,
	DAGGER       = 15,
	THROWN       = 16,
	SPEAR        = 17,
	CROSSBOW     = 18,
	WAND         = 19,
	FISHING_POLE = 20,
}

Enum.BuildCreator.ArmorSubClass = {
	MISC    = 0,
	CLOTH   = 1,
	LEATHER = 2,
	MAIL    = 3,
	PLATE   = 4,
	BUCKLER = 5,
	SHIELD  = 6,
	LIBRAM  = 7,
	IDOL    = 8,
	TOTEM   = 9,
	SIGIL   = 10,
}

Enum.BuildCreator.SaveResult = {
	Ok                            = 0,
	TooLowLevel                   = 1,
	NoSpells                      = 2,
	NoWeaponTypes                 = 3,
	NoArmorTypes                  = 4,
	DefaultOrNoName               = 5,
	DefaultOrNoIcon               = 6,
	DefaultOrNoDescription        = 7,
	LevelInappropriateSpell       = 8,
	FailedToCreateBuildInternally = 9,
	BadPermissions                = 10,
	FailedToUpdateBuildInternally = 11,
	FailedQualityRestrictions     = 12,
	BadCategory                   = 13,
	NotEnoughAEInvestment         = 14,
	NotEnoughTEInvestment         = 15,
}

Enum.BuildCreator.Difficulty = {
	Standard     = "BUILD_DIFFICULTY_RATING_EASY",
	Intermediate = "BUILD_DIFFICULTY_RATING_NORMAL",
	Advanced     = "BUILD_DIFFICULTY_RATING_HARD",
	Expert       = "BUILD_DIFFICULTY_RATING_VERY_HARD",
	Impossible   = "BUILD_DIFFICULTY_RATING_IMPOSSIBLE",
}

Enum.BuildCreator.SpellFlags = {
	DontShowBuildDraftCard = 0x1,
}

--
-- POI
--

Enum.POIFlags = {
	None                     = 0x0,
	Disabled                 = 0x1,
	Dynamic                  = 0x2,
	HideOnContinent          = 0x4,
	OnlyInCity               = 0x8,
	HasTooltip               = 0x10,
	AllianceOnly             = 0x20,
	HordeOnly                = 0x40,
	NoRiskOnly               = 0x80,
	HighRiskOnly             = 0x100,
	InactiveHideOnContinent  = 0x200,
	ShowOnMinimap            = 0x400,
	ShowOnMinimapOnlyInRange = 0x800,
	HighRiskGearEvent        = 0x1000,
    Timed                    = 0x2000,
    EventRequired            = 0x4000,
}

Enum.POIType = {
	None 			= "None",
	Instance 		= "Instance",
	Teleport 		= "Teleport",
	HighRiskEvent 	= "HighRiskEvent",
	Event 			= "Event",
	WorldBoss 		= "WorldBoss",
	Invasion 		= "Invasion",
	Hotspot 		= "Hotspot",
	FlightMaster 	= "FlightMaster",
	ChallengeDeath  = "ChallengeDeath",
	Townsfolk		= "Townsfolk",
}

--
-- Game Mode
--
Enum.GameMode = {
	None             = 0x00,
	Random           = 0x01,
	Ironman          = 0x02,
	Survivalist      = 0x04,
	Draft            = 0x08,
	Resolute         = 0x20,
	WildCard         = 0x40,
	Felforged        = 0x80,
	Nightmare        = 0x100,
	FreepickRarities = 0x400,
	BuildDraft       = 0x800,
	Crusader         = 0x1000,
}

--
-- Character Select
--
Enum.CharacterSelect = {}

Enum.CharacterSelect.Ruleset = {
	NoRisk   = 0,
	HighRisk = 1,
	Max      = 2,
}

Enum.CharacterSelect.Faction = {
	Horde    = 67,
	Alliance = 469,
	Other    = 0,
}

Enum.RealmGameMode = {
	Freepick                      = 0,
	Random                        = 1,
	Ironman                       = 2,
	Survivalist                   = 3,
	Draft                         = 4,
	Resolute                      = 5,
	WildCard                      = 6,
	Felforged                     = 7,
	Nightmare                     = 8,
	CharacterAdvancementQualities = 9,
	BuildDraft                    = 10,
	ConquestOfAzeroth             = 11,
	WarcraftReborn                = 12
}
--
-- Action Bars
--
Enum.ActionButtonType = {
	Spell  = 0x00,
	C      = 0x01,
	EQSET  = 0x20,
	Macro  = 0x40,
	CMacro = 0x41,
	Item   = 0x80,
}

--
-- Game Events
--
Enum.GameEvent = {
	TBCMythics               = 365,
	TBCHeroics               = 339,
	HeroicHellfire           = 400,
	HeroicCoilfang           = 401,
	HeroicAuchindoun         = 402,
	HeroicTempestKeep        = 403,
	HeroicCavernsOfTime      = 404,
	MythicHellfire           = 221,
	MythicCoilfang           = 222,
	MythicAuchindoun         = 223,
	MythicTempestKeep        = 224,
	MythicCavernsOfTime      = 225,

	HeroicBlackrockSpire     = 394,
	HeroicBlackrockDepths    = 395,
	HeroicScholomance        = 396,
	HeroicStratholme         = 436,
	HeroicMaraudon           = 437,
	HeroicDireMaul           = 447,
	MythicBlackrockSpire     = 728,
	MythicBlackrockDepths    = 729,
	MythicScholomance        = 730,
	MythicStratholme         = 731,
	MythicMaraudon           = 732,
	MythicDireMaul           = 734,

	BloodBowl                = 127,
	BloodBowl2               = 921,
	ArenaFrenzySunday        = 724,
	ArenaFrenzyThursday      = 920,
    ArenaFrenzySundayLate    = 970,
    ArenaFrenzyThursdayLate  = 971,
    ArenaFrenzy3v3           = 1183,
	CrowsCache               = 114,

	TBCHighRiskMaterials     = 926,
	VanillaHighRiskMaterials = 1100,

	HighRiskZG               = 150, -- 01. Vanilla: Zul'Gurub world loot enable
	HighRiskMC               = 151, -- 05. Vanilla: Molten Core world loot enable
	HighRiskONY              = 152, -- 03. Vanilla: Onyxia world loot enable
	HighRiskBWL              = 153, -- 08. Vanilla: Blackwing Lair world loot enable
	HighRiskAQR              = 154, -- 13. Vanilla: Ruins of Ahn'Qiraj world loot enable
	HighRiskAQT              = 157, -- 14. Vanilla: Temple of Ahn'Qiraj world loot enable
	HighRiskNAXX             = 162, -- 17. Vanilla: Naxxramas world loot enable

	Chapter1Tier1            = 455, -- [Seasonal] - [Chapter 1] [Tier 1]
	Chapter1Tier2            = 456, -- [Seasonal] - [Chapter 1] [Tier 2]
	Chapter1Tier3            = 457, -- [Seasonal] - [Chapter 1] [Tier 3]
	Chapter1Tier4            = 458, -- [Seasonal] - [Chapter 1] [Tier 4]
	Chapter1Tier5            = 459, -- [Seasonal] - [Chapter 1] [Tier 5]
	Chapter1Tier6            = 460, -- [Seasonal] - [Chapter 1] [Tier 6]
	Chapter1Tier7            = 461, -- [Seasonal] - [Chapter 1] [Tier 7]
	Chapter2Tier1            = 463, -- [Seasonal] - [Chapter 2] [Tier 1]
	Chapter2Tier2            = 464, -- [Seasonal] - [Chapter 2] [Tier 2]
	Chapter2Tier3            = 465, -- [Seasonal] - [Chapter 2] [Tier 3]
	Chapter2Tier4            = 466, -- [Seasonal] - [Chapter 2] [Tier 4]
	Chapter2Tier5            = 467, -- [Seasonal] - [Chapter 2] [Tier 5]
	Chapter2Tier6            = 468, -- [Seasonal] - [Chapter 2] [Tier 6]
	Chapter2Tier7            = 469, -- [Seasonal] - [Chapter 2] [Tier 7]
	Chapter3Tier1            = 470, -- [Seasonal] - [Chapter 3] [Tier 1]
	Chapter3Tier2            = 471, -- [Seasonal] - [Chapter 3] [Tier 2]
	Chapter3Tier3            = 472, -- [Seasonal] - [Chapter 3] [Tier 3]
	Chapter3Tier4            = 473, -- [Seasonal] - [Chapter 3] [Tier 4]
	Chapter3Tier5            = 474, -- [Seasonal] - [Chapter 3] [Tier 5]
	Chapter3Tier6            = 475, -- [Seasonal] - [Chapter 3] [Tier 6]
	Chapter3Tier7            = 476, -- [Seasonal] - [Chapter 3] [Tier 7]
	Chapter4Tier1            = 477, -- [Seasonal] - [Chapter 4] [Tier 1]
	Chapter4Tier2            = 478, -- [Seasonal] - [Chapter 4] [Tier 2]
	Chapter4Tier3            = 479, -- [Seasonal] - [Chapter 4] [Tier 3]
	Chapter4Tier4            = 480, -- [Seasonal] - [Chapter 4] [Tier 4]
	Chapter4Tier5            = 481, -- [Seasonal] - [Chapter 4] [Tier 5]
	Chapter4Tier6            = 482, -- [Seasonal] - [Chapter 4] [Tier 6]
	Chapter4Tier7            = 483, -- [Seasonal] - [Chapter 4] [Tier 7]
}

--
-- Cache Query Groups
--
Enum.CacheQueryGroup = {
	Creatures   = 0x01,
	GameObjects = 0x02,
	Items       = 0x04,
	Quests      = 0x08,
	POIs        = 0x10,
	AreaPOIs    = 0x20,
	Spells      = 0x40,
	ALL         = 0xFF,
}

--
-- Stat Query Groups
--
Enum.StatQueryGroup = {
	None      = 0x0,
	MeleeHit  = 0x1,
	RangedHit = 0x2,
	SpellHit  = 0x4,
	Expertise = 0x8,
	OffHandHit = 0x10,
}

--
-- Quests
--
Enum.Quests = {}

-- Path to Ascension
Enum.Quests.PTAscension = {
	FelCommutationPortal_H = 1903551,
	FelCommutationPortal_A = 1903552,
	RankUpYourSpells       = 1903520,
	BloodBowl              = 580180,
	FactionLeader          = 580178,
	WorldBoss              = 580179,
	PetTalents             = 1903569,
}

-- Vanity Flags
Enum.VanityFlags = {
	CannotBeDelivered = 0x4,
	SeasonalShowcase  = 0x10,
	Consumable        = 0x20,
}

-- Vanity Categories
Enum.VanityCategory = {
	Convenience = 0x2000000,
	Mounts      = 0x4000000,
	Pets        = 0x8000000,
	Toys        = 0x10000000,
	Seasonal    = 0x20000000,
	Consumable  = 0x40000000,
	AzzarFaire  = 0x80000000,
}

Enum.VanityCategory.Weapons = {
	All         = 0x1FFFFF,
	Axe1H       = 0x100001,
	Axe2H       = 0x100002,
	Sword1H     = 0x100004,
	Sword2H     = 0x100008,
	Mace1H      = 0x100010,
	Mace2H      = 0x100020,
	Dagger      = 0x100040,
	Fist        = 0x100080,
	Shield      = 0x100100,
	Polearm     = 0x100200,
	Bow         = 0x100400,
	Gun         = 0x100800,
	Crossbow    = 0x101000,
	Thrown      = 0x102000,
	Wand        = 0x104000,
	Staff       = 0x108000,
	FishingPole = 0x110000,
	OffHand     = 0x120000,
}

Enum.VanityCategory.Armor = {
	Head     = 0x200001,
	Shoulder = 0x200002,
	Chest    = 0x200004,
	Waist    = 0x200008,
	Legs     = 0x200010,
	Feet     = 0x200020,
	Wrist    = 0x200040,
	Hands    = 0x200080,
	Back     = 0x200100,
	Cloth    = 0x200200,
	Leather  = 0x200400,
	Mail     = 0x200800,
	Plate    = 0x201000,
	Sets     = 0x202000,
}

Enum.VanityCategory.Spells = {
	Visual      = 0x400001,
	Effect      = 0x400002,
	Incarnation = 0x400004,
}

Enum.VanityCategory.Miscellaneous = {
	Shirt    = 0x800001,
	Tabard   = 0x800002,
	Backpack = 0x800004,
	Illusion = 0x800008,
}

Enum.VanityCategory.TamedPets = {
	Whistle     = 0x1000001,
	SummonStone = 0x1000002,
	Vellum      = 0x1000004,
	Warhorn     = 0x1000008,
	Lodestone   = 0x1000010
}

Enum.VanityCurrency = {
	SeasonalPoints = 1,
	DonationPoints = 2,
	BazaarTokens   = 3,
}

-- professions
Enum.RecipeSource = {
	Item    = 1,
	Trainer = 2,
	Other   = 3,
}

-- Keys
Enum.Key = {
	NONE           = 0xffffffff,
	SHIFT          = 0x0,
	LSHIFT         = 0x0,
	RSHIFT         = 0x1,
	CTRL           = 0x2,
	LCTRL          = 0x2,
	RCTRL          = 0x3,
	ALT            = 0x4,
	LALT           = 0x4,
	RALT           = 0x5,
	LASTMETAKEY    = 0x5,
	SPACE          = 0x20,
	["'"]          = 0x27,
	[","]          = 0x2c,
	["-"]          = 0x2d,
	["."]          = 0x2e,
	["/"]          = 0x2f,
	["0"]          = 0x30,
	["1"]          = 0x31,
	["2"]          = 0x32,
	["3"]          = 0x33,
	["4"]          = 0x34,
	["5"]          = 0x35,
	["6"]          = 0x36,
	["7"]          = 0x37,
	["8"]          = 0x38,
	["9"]          = 0x39,
	[";"]          = 0x3b,
	["="]          = 0x3d,
	A              = 0x41,
	B              = 0x42,
	C              = 0x43,
	D              = 0x44,
	E              = 0x45,
	F              = 0x46,
	G              = 0x47,
	H              = 0x48,
	I              = 0x49,
	J              = 0x4a,
	K              = 0x4b,
	L              = 0x4c,
	M              = 0x4d,
	N              = 0x4e,
	O              = 0x4f,
	P              = 0x50,
	Q              = 0x51,
	R              = 0x52,
	S              = 0x53,
	T              = 0x54,
	U              = 0x55,
	V              = 0x56,
	W              = 0x57,
	X              = 0x58,
	Y              = 0x59,
	Z              = 0x5a,
	["["]          = 0x5b,
	["]"]          = 0x5d,
	["\\"]         = 0x5c,
	["`"]          = 0x60,
	NUMPAD0        = 0x100,
	NUMPAD1        = 0x101,
	NUMPAD2        = 0x102,
	NUMPAD3        = 0x103,
	NUMPAD4        = 0x104,
	NUMPAD5        = 0x105,
	NUMPAD6        = 0x106,
	NUMPAD7        = 0x107,
	NUMPAD8        = 0x108,
	NUMPAD9        = 0x109,
	NUMPADPLUS     = 0x10a,
	NUMPADMINUS    = 0x10b,
	NUMPADMULTIPLY = 0x10c,
	NUMPADDIVIDE   = 0x10d,
	NUMPADDECIMAL  = 0x10e,
	PLUS           = 0x110,
	MINUS          = 0x111,
	BRACKET_OPEN   = 0x112,
	BRACKET_CLOSE  = 0x113,
	SEMICOLON      = 0x116,
	APOSTROPHE     = 0x117,
	COMMA          = 0x118,
	PERIOD         = 0x119,
	ESCAPE         = 0x200,
	ENTER          = 0x201,
	BACKSPACE      = 0x202,
	TAB            = 0x203,
	LEFT           = 0x204,
	UP             = 0x205,
	RIGHT          = 0x206,
	DOWN           = 0x207,
	INSERT         = 0x208,
	DELETE         = 0x209,
	HOME           = 0x20a,
	END            = 0x20b,
	PAGEUP         = 0x20c,
	PAGEDOWN       = 0x20d,
	CAPSLOCK       = 0x20e,
	NUMLOCK        = 0x20f,
	SCROLLLOCK     = 0x210,
	PAUSE          = 0x211,
	PRINTSCREEN    = 0x212,
	F1             = 0x300,
	F2             = 0x301,
	F3             = 0x302,
	F4             = 0x303,
	F5             = 0x304,
	F6             = 0x305,
	F7             = 0x306,
	F8             = 0x307,
	F9             = 0x308,
	F10            = 0x309,
	F11            = 0x30a,
	F12            = 0x30b,
	LAST           = 0x30c,
}

Enum.MouseButton = {
	Left 		= 0x1,
	Middle 		= 0x2,
	Right 		= 0x4,
	XButton1 	= 0x8,
	XButton2 	= 0x10,
	XButton3	= 0x20,
	XButton4 	= 0x40,
	XButton5 	= 0x80,
	XButton6 	= 0x100,
	XButton7 	= 0x200,
	XButton8 	= 0x400,
	XButton9 	= 0x800,
	XButton10 	= 0x1000,
	XButton11 	= 0x2000,
	XButton12 	= 0x4000,
}

--
-- Transmog
--
Enum.TransmogType = {
	Appearance  = 0,
	Illusion    = 1,
	SpellVisual = 2,
	Incarnation = 3,
	CosmeticPet = 4,
	Cosmetic    = 5,
}

Enum.TransmogArmorType = {
	None    = 0,
	Plate   = 1,
	Mail    = 2,
	Leather = 3,
	Cloth   = 4,
}

Enum.TransmogCollectionType = {
	None                           = 0,
	Head                           = 1,
	Shoulder                       = 2,
	Back                           = 3,
	Chest                          = 4,
	Shirt                          = 5,
	Tabard                         = 6,
	Wrist                          = 7,
	Hands                          = 8,
	Waist                          = 9,
	Legs                           = 10,
	Feet                           = 11,
	Wand                           = 12,
	OneHAxe                        = 13,
	OneHSword                      = 14,
	OneHMace                       = 15,
	Dagger                         = 16,
	Fist                           = 17,
	Shield                         = 18,
	Holdable                       = 19,
	TwoHAxe                        = 20,
	TwoHSword                      = 21,
	TwoHMace                       = 22,
	Staff                          = 23,
	Polearm                        = 24,
	Bow                            = 25,
	Gun                            = 26,
	Crossbow                       = 27,
	Warglaives                     = 28,
	Paired                         = 29,
	Misc                           = 30,
	Thrown                         = 31,
	Fishing                        = 32,
	Illusion                       = 33,
	SpellVisual                    = 34,
	IncarnationBearForm            = 35,
	IncarnationCatForm             = 36,
	IncarnationTravelForm          = 37,
	IncarnationAquaticForm         = 38,
	IncarnationFlightForm          = 39,
	IncarnationMoonkinForm         = 40,
	IncarnationTreeOfLife          = 41,
	IncarnationGhostWolf           = 42,
	IncarnationImp                 = 43,
	IncarnationVoidwalker          = 44,
	IncarnationSuccubus            = 45,
	IncarnationFelhunter           = 46,
	IncarnationFelguard            = 47,
	IncarnationFelguardWeapon      = 48,
	IncarnationMetamorphosis       = 49,
	IncarnationAmmunition          = 50,
	CosmeticPetBeastmastersWhistle = 51,
	CosmeticPetSummonersStone      = 52,
	CosmeticPetBloodSoakedVellum   = 53,
	CosmeticPetDraconicWarhorn     = 54,
	CosmeticPetElementalLodestone  = 55,
	CosmeticOnPlayerEnterMap       = 56,
	CosmeticOnResurrect            = 57,
	CosmeticAutoLootPet            = 58,
	CosmeticHunterPet              = 59,
	CosmeticDemonPet               = 60,
	CosmeticUndeadPet              = 61,
	CosmeticElementalPet           = 62,
	CosmeticDragonkinPet           = 63,
	CosmeticMechanicalPet          = 64,
	CosmeticGiantPet               = 65,
	CosmeticAberrationPet          = 66,
}

Enum.TransmogPendingType = {
	Apply     = 0,
	Revert    = 1,
	ToggleOn  = 2,
	ToggleOff = 3,
}

Enum.TransmogIllusionSlot = {
	MainHand = 0,
	OffHand  = 1,
}

Enum.SpellSlot = {}

Enum.IncarnationSlot = {
	BearForm       = 0,
	CatForm        = 1,
	TravelForm     = 2,
	AquaticForm    = 3,
	FlightForm     = 4,
	MoonkinForm    = 5,
	TreeOfLife     = 6,
	GhostWolf      = 7,
	Imp            = 8,
	Voidwalker     = 9,
	Succubus       = 10,
	Felhunter      = 11,
	Felguard       = 12,
	FelguardWeapon = 13,
	Metamorphosis  = 14,
	Ammunition     = 15,
}

Enum.CosmeticPetSlot = {
	BeastmastersWhistle = 0,
	SummonersStone      = 1,
	BloodSoakedVellum   = 2,
	DraconicWarhorn     = 3,
	ElementalLodestone  = 4,
}

Enum.CosmeticSlot = {
	OnPlayerEnterMap = 1,
	OnResurrect      = 2,
	AutoLootPet      = 3,
	HunterPet        = 4,
	DemonPet         = 5,
	UndeadPet        = 6,
	ElementalPet     = 7,
	DragonkinPet     = 8,
	MechanicalPet    = 9,
	GiantPet         = 10,
	AberrationPet    = 11,
}

Enum.TransmogSlotID = {
	Head      = 0,
	Shoulders = 1,
	Chest     = 2,
	Waist     = 3,
	Legs      = 4,
	Feet      = 5,
	Wrists    = 6,
	Hands     = 7,
	Back      = 8,
	MainHand  = 9,
	OffHand   = 10,
	Ranged    = 11,
	Tabard    = 12,
	Body      = 13,
}

--
-- Mystic Enchants
--
Enum.REFlags = {
	None        = 0x0,
	WorldForged = 0x1,
	Development = 0x2,
	ArmorOnly   = 0x4,
}

Enum.REComplexity = {
	Easy   = 1,
	Medium = 2,
	Hard   = 3,
}

--
-- Professions
--

Enum.Profession = {
	Blacksmithing  = 164,
	Alchemy        = 171,
	Enchanting     = 333,
	Engineering    = 202,
	Jewelcrafting  = 755,
	Inscription    = 773,
	Leatherworking = 165,
	Tailoring      = 197,
	Herbalism      = 182,
	Mining         = 186,
	Skinning       = 393,
	Cooking        = 185,
	FirstAid       = 129,
	Fishing        = 356,
	Woodcutting    = 732,
    Woodworking    = 757,
    Bushcraft     = 505,
}

--
-- PvE
--
Enum.DungeonDifficulty = {
	Normal = 0,
	Heroic = 1,
	Mythic = 2,
}

Enum.RaidDifficulty = {
	Normal   = 0,
	Heroic   = 1,
	Mythic   = 2,
	Ascended = 3,
}

--
-- BugReporter
--
Enum.BugReport = {
	Category = {
		Abilities          = 0,
		Talents            = 1,
		MysticEnchants     = 2,
		Dungeons           = 3,
		Raids              = 4,
		Quests             = 5,
		Items              = 6,
		Interface          = 7,
		WebsiteAndLauncher = 8,
		Other              = 9,
	},
	Priority = {
		Low          = 0,
		Medium       = 1,
		High         = 2,
		GameBreaking = 3,
	},
}

--
-- Power Types
--
Enum.PowerType = {
	MANA        = 0,
	RAGE        = 1,
	FOCUS       = 2,
	ENERGY      = 3,
	HAPPINESS   = 4,
	RUNES       = 5,
	RUNIC_POWER = 6,
}

Enum.CustomPowerType = {
	Default 	= -1,
	ShadowOrbs3 = 1,
	ShadowOrbs5 = 2,
	HolyPower3  = 3,
	HolyPower5  = 4,
}

--
-- Challenges
--
Enum.ChallengeDifficulty = {
	CHALLENGE_DIFFICULTY_EASY       = 1,
	CHALLENGE_DIFFICULTY_NORMAL     = 2,
	CHALLENGE_DIFFICULTY_HARD       = 3,
	CHALLENGE_DIFFICULTY_VERY_HARD  = 4,
	CHALLENGE_DIFFICULTY_IMPOSSIBLE = 5,
}

Enum.ChallengeResponse = {
	CHALLENGE_START_OK                           = 0,
	CHALLENGE_START_NOT_FOUND                    = 1,
	CHALLENGE_START_NO_REWARDS                   = 2,
	CHALLENGE_START_WRONG_GAME_MODE              = 3,
	CHALLENGE_START_ALREADY_ACTIVE               = 4,
	CHALLENGE_START_EXCLUSIVE_GROUP_ACTIVE       = 5,
	CHALLENGE_START_GAME_EVENT_NOT_ACTIVE        = 6,
	CHALLENGE_START_DISABLED                     = 7,
	CHALLENGE_START_CONDITIONS_NOT_MET           = 8,
	CHALLENGE_START_PREVIOUS_LEVEL_NOT_COMPLETED = 9,
	CHALLENGE_START_OUTSIDE_INTERACTION          = 10,
	CHALLENGE_START_NOT_PRESTIGE                 = 11,
	CHALLENGE_START_RULE_BROKEN                  = 12,
	CHALLENGE_START_PARTICIPATING_IN_TRIAL       = 13,
	CHALLENGE_START_PARTICIPATING_IN_CHALLENGE   = 14,
}

Enum.ChallengeStopResponse = {
	CHALLENGE_STOP_OK              = 0,
	CHALLENGE_STOP_NOT_ACTIVE      = 1,
	CHALLENGE_STOP_DEATH_CHALLENGE = 2,
}

Enum.TrialActivateResponse = {
	ACTIVATE_TRIAL_OK                        = 0,
	ACTIVATE_TRIAL_NOT_FOUND                 = 1,
	ACTIVATE_TRIAL_ALREADY_ACTIVE            = 2,
	ACTIVATE_TRIAL_CANNOT_ACTIVATE_CHALLENGE = 3,
}

Enum.TrialDeactivateResponse = {
	DEACTIVATE_TRIAL_OK                          = 0,
	DEACTIVATE_TRIAL_NO_ACTIVE_CHALLENGE         = 1,
	DEACTIVATE_TRIAL_NOT_FOUND                   = 2,
	DEACTIVATE_TRIAL_CANNOT_DEACTIVATE_CHALLENGE = 3,
}

Enum.TrialSaveResponse = {
	SAVE_TRIAL_OK                         = 0,
	SAVE_TRIAL_DOES_NOT_EXIST             = 1,
	SAVE_TRIAL_NOT_OWNER                  = 2,
	SAVE_TRIAL_NO_TITLE                   = 3,
	SAVE_TRIAL_NO_CHALLENGES              = 4,
	SAVE_TRIAL_INVALID_ICON               = 5,
	SAVE_TRIAL_ID_TOO_LONG                = 6,
	SAVE_TRIAL_TITLE_TOO_LONG             = 7,
	SAVE_TRIAL_DESCRIPTION_TOO_LONG       = 8,
	SAVE_TRIAL_ICON_TOO_LONG              = 9,
	SAVE_TRIAL_ENTRY_DESCRIPTION_TOO_LONG = 10,
	SAVE_TRIAL_CANNOT_EDIT_CHALLENGES     = 11,
}

Enum.ChallengeFlag = {
	None           = 0x0,
	Disabled       = 0x1,
	LinearProgress = 0x2,
}

Enum.ChallengeFilter = {
	Trial = "FILTER_TRIAL",
	Challenge = "FILTER_CHALLENGE",
	DungeonTrial = "FILTER_DUNGEON_TRIAL",
	Prestige = "FILTER_PRESTIGE",
	NotPrestige = "FILTER_NOT_PRESTIGE",
	CanActivate = "FILTER_CAN_ACTIVATE",
	PvE = "FILTER_PVE",
	PvP = "FILTER_PVP",
	Solo = "FILTER_SOLO",
	Group = "FILTER_GROUP",
	Easy = "FILTER_DIFFICULTY_EASY",
	Normal = "FILTER_DIFFICULTY_NORMAL",
	Hard = "FILTER_DIFFICULTY_HARD",
	VeryHard = "FILTER_DIFFICULTY_VERY_HARD",
	Impossible = "FILTER_DIFFICULTY_IMPOSSIBLE",
}

Enum.TypeID = {
	TYPEID_OBJECT        = 0,
	TYPEID_ITEM          = 1,
	TYPEID_CONTAINER     = 2,
	TYPEID_UNIT          = 3,
	TYPEID_PLAYER        = 4,
	TYPEID_GAMEOBJECT    = 5,
	TYPEID_DYNAMICOBJECT = 6,
	TYPEID_CORPSE        = 7,
}

Enum.TraitNodeEntryType = {
	SpendHex         = 0,
	SpendSquare      = 1,
	SpendCircle      = 2,
	SpendSmallCircle = 3,
	DeprecatedSelect = 4,
	DragAndDrop      = 5,
	SpendDiamond     = 6,
	ProfPath         = 7,
	ProfPerk         = 8,
	ProfPathUnlock   = 9,
}

Enum.TraitEdgeType = {
	VisualOnly                = 0,
	DeprecatedRankConnection  = 1,
	SufficientForAvailability = 2,
	RequiredForAvailability   = 3,
	MutuallyExclusive         = 4,
	DeprecatedSelectionOption = 5,
}

Enum.TraitEdgeVisualStyle = {
	None     = 0,
	Straight = 1,
}

Enum.UnlearnCost = {
	Gold                	     = 0,
	ScrollOfFortune    			 = 1,
	ScrollOfFortuneAbilities     = 2,
	ScrollOfFortuneTalents       = 3,
	ScrollOfUnlearning  		 = 1101243,
	MarksOfAscension    		 = 375250,
	AbilityPurge        		 = 383082,
	TalentPurge         		 = 383083,
	ClassPurge          		 = 919290,
	SpecializationPurge 		 = 919291,
	MysticOrb           		 = 98570,
	MysticRune          		 = 98462,
	MysticExtract       		 = 98463,
}

--
-- Help Menu
--
Enum.TicketQueueStatus = {
	Disabled = -1,
	Enabled  = 1,
}

Enum.TicketAssingedStatus = {
	NotAssigned = 0, -- ticket is not currently assigned to a gm
	Assigned    = 1, -- ticket is assigned to a normal gm
	Escalated   = 2, -- ticket is in the escalation queue
}

Enum.TicketSeenStatus = {
	Unread = 0, -- ticket has never been opened by a gm
	Read   = 1, -- ticket has been opened by a gm
}

--
-- Specialization
--
Enum.Complexity = {
	Normal     = 1,
	Medium     = 2,
	Hard       = 3,
	VeryHard   = 4,
	Impossible = 5,
}

--
-- Recovery Service
--
Enum.RecoveryCategory = {
	DisenchantedItems = 1,
	DeletedCharacters = 3,
	VendoredItems     = 4,
	DeletedItems      = 5,
	RecylcedItems     = 6,
    Worldforged       = 7,
	WildCardRoll 	  = 10,
}

--
-- New Roles
--
Enum.ClassRole = {
	MeleeDPS  = 1,
	RangedDPS = 2,
	CasterDPS = 3,
	Healer    = 4,
	Tank      = 5,
	Support   = 6,
}

Enum.ClassArmorType = {
	Plate   = 1,
	Mail    = 2,
	Leather = 3,
	Cloth   = 4,
}

--
-- Enchant Collection
--
Enum.ECSlotBorderStylesKnown = {
	[Enum.ItemQuality.Epic]      = "EnchantSlotBorderKnownEpic",
	[Enum.ItemQuality.Uncommon]  = "EnchantSlotBorderKnownUncommon",
	[Enum.ItemQuality.Legendary] = "EnchantSlotBorderKnownLegendary",
	[Enum.ItemQuality.Rare]      = "EnchantSlotBorderKnownRare",
	[Enum.ItemQuality.Vanity] = "EnchantSlotBorderKnownArtifact",
}

Enum.ECSlotBorderStylesUnKnown = {
	[Enum.ItemQuality.Epic]      = "EnchantSlotBorderUnknownEpic",
	[Enum.ItemQuality.Legendary] = "EnchantSlotBorderUnknownLegendary",
	[Enum.ItemQuality.Rare]      = "EnchantSlotBorderUnknownRare",
	[Enum.ItemQuality.Uncommon]      = "EnchantSlotBorderUnknownUncommon",
	[Enum.ItemQuality.Vanity]      = "EnchantSlotBorderUnknownArtifact",
}

--[[Enum.ECSlotQualityJewelStyles = {
	[Enum.ItemQuality.Epic]      = "EnchantQualityJewelEpic",
	[Enum.ItemQuality.Legendary] = "EnchantQualityJewelLegendary",
	[Enum.ItemQuality.Rare]      = "EnchantQualityJewelRare",
	[Enum.ItemQuality.Uncommon]      = "EnchantQualityJewelUncommon",
	[Enum.ItemQuality.Vanity]      = "EnchantQualityJewelArtifact",
}]]--

Enum.ECSlotQualityJewelStyles = {
	[Enum.ItemQuality.Epic]      = "EnchantSlotBorderUnknownEpic",
	[Enum.ItemQuality.Legendary] = "EnchantSlotBorderUnknownLegendary",
	[Enum.ItemQuality.Rare]      = "EnchantSlotBorderUnknownRare",
	[Enum.ItemQuality.Uncommon]      = "EnchantSlotBorderUnknownUncommon",
	[Enum.ItemQuality.Vanity]      = "EnchantSlotBorderUnknownArtifact",
}

Enum.ECQuestionMarkStyles = {
	[0] = "EnchantSlotQuestionMarkNormal",
}

Enum.ECSlotBorderStylesAnimated = {
	[Enum.ItemQuality.Epic]      = "EnchantSlotBorderAnimatedEpic",
	[Enum.ItemQuality.Legendary] = "EnchantSlotBorderAnimatedLegendary",
	[Enum.ItemQuality.Rare]      = "EnchantSlotBorderAnimatedRare",
	[Enum.ItemQuality.Uncommon]  = "EnchantSlotBorderAnimatedUncommon",
	[Enum.ItemQuality.Vanity]  = "EnchantSlotBorderAnimatedArtifact",
}

Enum.ECSlotStates = {
	Unknown = 1,
	Known   = 2,
	Locked  = 3,
}

Enum.EnchantQualityEnum = {
	RE_QUALITY_RARE      = Enum.ItemQuality.Rare,
	RE_QUALITY_UNCOMMON  = Enum.ItemQuality.Uncommon,
	RE_QUALITY_EPIC      = Enum.ItemQuality.Epic,
	RE_QUALITY_LEGENDARY = Enum.ItemQuality.Legendary,
	RE_QUALITY_POOR      = Enum.ItemQuality.Poor,
	RE_QUALITY_NORMAL    = Enum.ItemQuality.Common,
	RE_QUALITY_ARTIFACT  = Enum.ItemQuality.Vanity,
	RE_QUALITY_HEIRLOOM  = Enum.ItemQuality.Heirloom,
}

Enum.ECRarityFilters = {
	RE_FILTER_UNCOMMON  = Enum.ItemQuality.Uncommon,
	RE_FILTER_RARE      = Enum.ItemQuality.Rare,
	RE_FILTER_EPIC      = Enum.ItemQuality.Epic,
	RE_FILTER_LEGENDARY = Enum.ItemQuality.Legendary,
	RE_FILTER_ARTIFACT 	= Enum.ItemQuality.Vanity,
}

Enum.ECClassFilters = {
	RE_FILTER_CLASS_WARRIOR = Enum.Class.Warrior,
	RE_FILTER_CLASS_PALADIN = Enum.Class.Paladin,
	RE_FILTER_CLASS_HUNTER  = Enum.Class.Hunter,
	RE_FILTER_CLASS_ROGUE  = Enum.Class.Rogue,
	RE_FILTER_CLASS_PRIEST = Enum.Class.Priest,
	RE_FILTER_CLASS_DEATH_KNIGHT = Enum.Class.DeathKnight,
	RE_FILTER_CLASS_SHAMAN = Enum.Class.Shaman,
	RE_FILTER_CLASS_MAGE = Enum.Class.Mage,
	RE_FILTER_CLASS_WARLOCK = Enum.Class.Warlock,
	RE_FILTER_CLASS_HERO = Enum.Class.Hero,
	RE_FILTER_CLASS_DRUID = Enum.Class.Druid,
}

Enum.ECCollectionTabs = {
	ScrollsTab    = 1,
	CollectionTab = 2,
}

Enum.ECSlotTabs = {
	ReforgeTab 		= 1,
	SlotTab			= 2,
	ArchitectTab 	= 3,
}

Enum.ECFilters = {
	RE_FILTER_KNOWN           		= "RE_FILTER_KNOWN",
	RE_FILTER_UNKNOWN         		= "RE_FILTER_UNKNOWN",
	RE_FILTER_UNCOMMON        		= "RE_FILTER_UNCOMMON",
	RE_FILTER_RARE            		= "RE_FILTER_RARE",
	RE_FILTER_EPIC            		= "RE_FILTER_EPIC",
	RE_FILTER_LEGENDARY       		= "RE_FILTER_LEGENDARY",
	RE_FILTER_WORLDFORGED     		= "RE_FILTER_WORLDFORGED",
	RE_FILTER_NOT_WORLDFORGED 		= "RE_FILTER_NOT_WORLDFORGED",
	RE_FILTER_CLASS_WARRIOR			= "RE_FILTER_CLASS_WARRIOR",
	RE_FILTER_CLASS_PALADIN			= "RE_FILTER_CLASS_PALADIN",
	RE_FILTER_CLASS_HUNTER			= "RE_FILTER_CLASS_HUNTER",
	RE_FILTER_CLASS_ROGUE			= "RE_FILTER_CLASS_ROGUE",
	RE_FILTER_CLASS_PRIEST			= "RE_FILTER_CLASS_PRIEST",
	RE_FILTER_CLASS_DEATH_KNIGHT	= "RE_FILTER_CLASS_DEATH_KNIGHT",
	RE_FILTER_CLASS_SHAMAN			= "RE_FILTER_CLASS_SHAMAN",
	RE_FILTER_CLASS_MAGE			= "RE_FILTER_CLASS_MAGE",
	RE_FILTER_CLASS_WARLOCK			= "RE_FILTER_CLASS_WARLOCK",
	RE_FILTER_CLASS_HERO			= "RE_FILTER_CLASS_HERO",
	RE_FILTER_CLASS_DRUID			= "RE_FILTER_CLASS_DRUID",
}

--
-- Skill Card Collection
--
Enum.SkillCardType = {
	SkillNormal = "SKILL_CARD_DEFAULT_NORMAL",
    SkillGolden = "SKILL_CARD_DEFAULT_GOLDEN",
    StarterNormal = "SKILL_CARD_STARTER_NORMAL",
    StarterGolden = "SKILL_CARD_STARTER_GOLDEN",
    LuckyNormal = "SKILL_CARD_LUCKY_NORMAL",
    LuckyGolden = "SKILL_CARD_LUCKY_GOLDEN",
    TalentNormal = "SKILL_CARD_TALENT_NORMAL",
    TalentGolden = "SKILL_CARD_TALENT_GOLDEN",
}

Enum.SkillCardQualityNames = {
	Common = "SKILL_CARD_COMMON",
	Uncommon = "SKILL_CARD_UNCOMMON",
    Rare = "SKILL_CARD_RARE",
    Epic = "SKILL_CARD_EPIC",
    Legendary = "SKILL_CARD_LEGENDARY",
	Artifact = "SKILL_CARD_ARTIFACT",
}

Enum.SkillCardQuality = {
	[Enum.SkillCardQualityNames.Common] = Enum.ItemQuality.Common,
	[Enum.SkillCardQualityNames.Uncommon] = Enum.ItemQuality.Uncommon,
    [Enum.SkillCardQualityNames.Rare] = Enum.ItemQuality.Rare,
    [Enum.SkillCardQualityNames.Epic] = Enum.ItemQuality.Epic,
    [Enum.SkillCardQualityNames.Legendary] = Enum.ItemQuality.Legendary,
	[Enum.SkillCardQualityNames.Artifact] = Enum.ItemQuality.Artifact,
}

Enum.SkillCardTabs = {
	SkillCardsTab 	= 1,
	StarterCardsTab = 2,
	LuckyCardsTab 	= 3,
	TalentCardsTab 	= 4,
	BoostersTab 	= 5,
}

Enum.SkillCardFilters = {
    Common = "FILTER_COMMON",
    Uncommon = "FILTER_UNCOMMON",
    Rare = "FILTER_RARE",
    Epic = "FILTER_EPIC",
    Legendary = "FILTER_LEGENDARY",
	Artifact = "FILTER_ARTIFACT",
    Collected = "FILTER_COLLECTED",
    NotCollected = "FILTER_NOT_COLLECTED",
    Starters = "FILTER_STARTER",
}

Enum.SkillCardPurchaseCardTypes = {
	NORMAL_LEGENDARY_ABILITIES = "PURCHASE_SEALED_CARD_TYPE_NORMAL_LEGENDARY_ABILITIES",
	NORMAL_EPIC_ABILITIES = "PURCHASE_SEALED_CARD_TYPE_NORMAL_EPIC_ABILITIES",
	NORMAL_RARE_ABILITIES = "PURCHASE_SEALED_CARD_TYPE_NORMAL_RARE_ABILITIES",
	NORMAL_UNCOMMON_ABILITIES = "PURCHASE_SEALED_CARD_TYPE_NORMAL_UNCOMMON_ABILITIES",
	NORMAL_COMMON_ABILITIES = "PURCHASE_SEALED_CARD_TYPE_NORMAL_COMMON_ABILITIES",
	NORMAL_LEGENDARY_TALENTS = "PURCHASE_SEALED_CARD_TYPE_NORMAL_LEGENDARY_TALENTS",
	NORMAL_EPIC_TALENTS = "PURCHASE_SEALED_CARD_TYPE_NORMAL_EPIC_TALENTS",
	NORMAL_RARE_TALENTS = "PURCHASE_SEALED_CARD_TYPE_NORMAL_RARE_TALENTS",
	NORMAL_UNCOMMON_TALENTS = "PURCHASE_SEALED_CARD_TYPE_NORMAL_UNCOMMON_TALENTS",
	NORMAL_COMMON_TALENTS = "PURCHASE_SEALED_CARD_TYPE_NORMAL_COMMON_TALENTS",
	GOLDEN_LEGENDARY_ABILITIES = "PURCHASE_SEALED_CARD_TYPE_GOLDEN_LEGENDARY_ABILITIES",
	GOLDEN_EPIC_ABILITIES = "PURCHASE_SEALED_CARD_TYPE_GOLDEN_EPIC_ABILITIES",
	GOLDEN_RARE_ABILITIES = "PURCHASE_SEALED_CARD_TYPE_GOLDEN_RARE_ABILITIES",
	GOLDEN_UNCOMMON_ABILITIES = "PURCHASE_SEALED_CARD_TYPE_GOLDEN_UNCOMMON_ABILITIES",
	GOLDEN_COMMON_ABILITIES = "PURCHASE_SEALED_CARD_TYPE_GOLDEN_COMMON_ABILITIES",
	GOLDEN_LEGENDARY_TALENTS = "PURCHASE_SEALED_CARD_TYPE_GOLDEN_LEGENDARY_TALENTS",
	GOLDEN_EPIC_TALENTS = "PURCHASE_SEALED_CARD_TYPE_GOLDEN_EPIC_TALENTS",
	GOLDEN_RARE_TALENTS = "PURCHASE_SEALED_CARD_TYPE_GOLDEN_RARE_TALENTS",
	GOLDEN_UNCOMMON_TALENTS = "PURCHASE_SEALED_CARD_TYPE_GOLDEN_UNCOMMON_TALENTS",
	GOLDEN_COMMON_TALENTS = "PURCHASE_SEALED_CARD_TYPE_GOLDEN_COMMON_TALENTS",
	DEFAULT_PACK = "PURCHASE_SEALED_CARD_TYPE_DEFAULT_PACK",
    DEFAULT_GOLDEN_PACK = "PURCHASE_SEALED_CARD_TYPE_DEFAULT_GOLDEN_PACK",
    DEFAULT_TALENT_PACK = "PURCHASE_SEALED_CARD_TYPE_DEFAULT_TALENT_PACK",
    DEFAULT_GOLDEN_TALENT_PACK = "PURCHASE_SEALED_CARD_TYPE_DEFAULT_GOLDEN_TALENT_PACK",
}

Enum.ScrollsOfFortune = {
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_I",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_II",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_III",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_IV",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_V",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_VI",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_VII",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_VIII",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_IX",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_X",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XI",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XII",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XIII",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XIV",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XV",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XVI",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XVII",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XVIII",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XIX",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XX",
}

Enum.ScrollsOfFortuneAbilities = {
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_I_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_II_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_III_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_IV_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_V_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_VI_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_VII_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_VIII_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_IX_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_X_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XI_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XII_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XIII_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XIV_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XV_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XVI_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XVII_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XVIII_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XIX_ABILITIES",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XX_ABILITIES",
}

Enum.ScrollsOfFortuneTalents = {
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_I_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_II_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_III_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_IV_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_V_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_VI_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_VII_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_VIII_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_IX_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_X_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XI_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XII_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XIII_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XIV_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XV_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XVI_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XVII_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XVIII_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XIX_TALENTS",
    "TOKEN_TYPE_SCROLL_OF_FORTUNE_XX_TALENTS",
}

--
-- CoA Talents
--
Enum.ConditionTypes = {
    playerLevel = 1,
    currencyAE  = 2,
    currencyTE  = 3,
}

Enum.TraitNodeType = {
    Single = 0,
    Tiered = 1,
    Selection = 2,
}

Enum.ResetTypes = {
    AbilityAndTalentReset = 1,
    TalentReset = 2,
    AbilityReset = 3
}

Enum.LootToastBit = {
	EpicItem = 1,
	LegendaryItem = 2,
	NewSpellRank = 3,
	SpellLearned = 4,
}

Enum.QuestStatus = {
	Collect = "collect",
	Objective = "objective",
	Unavailable = "unavailable",
	PickUp = "pickup",
	Trivial = "trivial",
	Complete = "handin",
	Incomplete = "incomplete",
}

Enum.TutorialExperience = {
	NoTutorials = -1,
	NewToAscension = 1,
	NewToWoW = 2,
}

Enum.SuperTrackingType = {
	Corpse = 1,
	Position = 2,
	Quest = 3,
}

Enum.NavigationState = {
	Invalid = 0,
	Occluded = 1,
	InRange = 2,
	Disabled = 3,
	InRadius = 4,
}

Enum.CharacterAdvancementCategories = {
	CoreDamage = 1,
	PowerAbility = 2,
	Movement = 3,
	Buff = 4,
}

Enum.CharCreateSteps = {
	TutorialLevel = "TUTORIALLEVEL",
	ClassRace = "CLASSRACE",
	Customization = "CUSTOMIZATION",
	Role = "ROLE",
	Subrole = "SUBROLE",
	Archetype = "ARCHETYPE",
	NameEdit = "NAMEEDIT",
}

Enum.CharCreateArchetypeBases = {
	Freepick = 2,
	UseArchetype = 1,
}

Enum.CustomStores = {
	TrialMasters = 1,
	BuildMasters = 2,
	DarkmoonPrizes = 4,
	SkillCards = 5,
	GoldenSkillCards = 6,
	HeirloomWeapons = 7,
	RPGWeaponStore = 8,
    RPGArmorStore = 9,
	CoAClassBundleStore = 10,
	CoAClassBundleStore2 = 11,
}

Enum.ScreenLocationType = {
	Center				= 1,
	Left				= 2,
	Top					= 3,
	TopRight			= 4,
	TopLeft				= 5,
	Right				= 6,
	LeftRight			= 7,
	Bottom				= 8,
	TopBottom			= 9,
	LeftOutside			= 10,
	RightOutside		= 11,
	LeftRightOutside	= 12,
}

Enum.UIActionType = {
	Forbidden	= 17,
	HWEvent		= 23,
	NoCombat	= 22,
	NoScript	= 26,
}

Enum.TicketPriority = {
	Low 	= "LOW",
	Medium 	= "MEDIUM",
	High 	= "HIGH",
	Urgent 	= "URGENT"
}

Enum.DBCLocale = {
	LOCALE_DBC_xxXX = "UNKNOWN",
	LOCALE_DBC_enUS = "enUS",
	LOCALE_DBC_enGB = "enGB",
	LOCALE_DBC_koKR = "koKR",
	LOCALE_DBC_frFR = "frFR",
	LOCALE_DBC_deDE = "deDE",
	LOCALE_DBC_enCN = "enCN",
	LOCALE_DBC_zhCN = "zhCN",
	LOCALE_DBC_enTW = "enTW",
	LOCALE_DBC_zhTW = "zhTW",
	LOCALE_DBC_esES = "esES",
	LOCALE_DBC_esMX = "esMX",
	LOCALE_DBC_ruRU = "ruRU",
	LOCALE_DBC_ptPT = "ptPT",
	LOCALE_DBC_ptBR = "ptBR",
	LOCALE_DBC_itIT = "itIT",
	LOCALE_DBC_Unk  = "UNKNOWN",
}

Enum.TicketCategory = {
	Other 			= "GM_TICKET_CATEGORY_OTHER",
	Talents 		= "GM_TICKET_CATEGORY_TALENTS",
	Dungeons 		= "GM_TICKET_CATEGORY_DUNGEONS",
	Items 			= "GM_TICKET_CATEGORY_ITEMS",
	Spells 			= "GM_TICKET_CATEGORY_SPELLS_AND_ABILITIES",
	Web 			= "GM_TICKET_CATEGORY_WEBSITE_OR_LAUNCHER",
	MysticEnchants 	= "GM_TICKET_CATEGORY_MYSTIC_ENCHANTS",
	Raids 			= "GM_TICKET_CATEGORY_RAIDS",
	Quests 			= "GM_TICKET_CATEGORY_QUESTS",
	Interface 		= "GM_TICKET_CATEGORY_UI_OR_ADDONS",
}

Enum.GossipMenu = {
	Nozdormu = 40320,
}

Enum.GameObject = {
	FelCommutationPortal = 8000053
}
