-- globalstrings
StaticPopupDialogs["ASC_APPLY_EC_CONFIRM"] = { -- TODO: Replace with improved input block frame
        --text = "ERROR!",
        button1 = ACCEPT,
        button2 = CANCEL,
        whileDead = true,
        timeout = 0,
        hideOnEscape = true,
        OnShow = function(self, data)
            self.button1:SetEnabled(StaticPopupDialogs["ASC_APPLY_EC_CONFIRM"].canPay)
            C_Hook:SendEvent("ENCHANTCOLLECTION_DIALOGUE_SHOW")
        end,
        OnHide = function(self)
            C_Hook:SendEvent("ENCHANTCOLLECTION_DIALOGUE_HIDE")
        end,
}
-------------------------------------------------------------------------------
--                           EnchantCollectionUtil                           --
-------------------------------------------------------------------------------
EnchantCollectionUtil = CreateFrame("FRAME")
EnchantCollectionUtil:HookEvent("MYSTIC_ALTAR_USED")
EnchantCollectionUtil:HookEvent("MYSTIC_ALTAR_CLOSED")
EnchantCollectionUtil:HookEvent("MYSTIC_SCROLL_USED")
EnchantCollectionUtil:HookEvent("MYSTIC_ENCHANT_UNLOCK_PRESET_USED")
EnchantCollectionUtil:HookEvent("MYSTIC_ENCHANT_LEARNED")
EnchantCollectionUtil:HookEvent("MYSTIC_ENCHANT_PROGRESS_UPDATE")

EnchantCollectionUtil.tempSlotData = {}
EnchantCollectionUtil.maxSlots = NUM_MYSTIC_ENCHANT_SLOTS
EnchantCollectionUtil.maxCollectionButtons = 18
EnchantCollectionUtil.unknownEnchantColor = CreateColorFromCode("|cff5d50bf")

EnchantCollectionUtil.dialogues = {
	"ASC_APPLY_EC_CONFIRM",
}

EnchantCollectionUtil.specialErrors = {
	RE_REFORGE_NO_MYSTIC_ALTAR = true,
	RE_COLLECTION_REFORGE_NO_MYSTIC_ALTAR = true,
	RE_DISENCHANT_NO_MYSTIC_ALTAR = true,
	RE_APPLY_NO_MYSTIC_ALTAR = true,
	RE_PURCHASE_NO_MYSTIC_ALTAR = true,
}

-- TODO: Calculate
local function CalcPos(fi, radius)
    return radius*cos(fi), radius*sin(fi)
end

local RADIUS_1 = 96
local RADIUS_2 = 192
local DRAFT_RADIUS_2 = 198
local CLASS_FUSION_CONFIG = "CONFIG_CLASS_FUSION_ENABLED"
local OUTER_RING_SLOT_IDS = {8, 9, 10, 11, 12, 13, 14, 15, 16, 17}
local DEFAULT_OUTER_RING_ANGLES = {45, 15, -15, -45, -75, -105, -135, -165, 165, 135}
local HERO_FREEPICK_EPIC_SLOT_IDS = {2, 3, 4, 1}
local HERO_FREEPICK_RARE_SLOT_IDS = {7, 5, 11, 6, 8}
local HERO_FREEPICK_GREEN_SLOT_IDS = {9, 10, 12, 13, 14, 15}
local HERO_FREEPICK_VISIBLE_SLOT_IDS = {2, 3, 4, 1, 7, 5, 11, 6, 8, 9, 10, 12, 13, 14, 15}
local HERO_FREEPICK_REAL_SLOT_IDS = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
local HERO_FREEPICK_SLOT_MAP_LAYOUT = "HERO_FREEPICK_V2"
local HERO_FREEPICK_EPIC_RADIUS = 85.6
local HERO_FREEPICK_EPIC_ANGLES = {
	[2] = -30,
	[3] = -150,
	[4] = 90,
}
local HERO_FREEPICK_RARE_ANGLES = {-150, -120, -90, -60, -30}
local HERO_FREEPICK_GREEN_ANGLES = {165, 135, 105, 75, 45, 15}

local function SetOuterRingAngles(slotIDs, angles, radius)
	slotIDs = slotIDs or OUTER_RING_SLOT_IDS
	radius = radius or RADIUS_2

	for index, slotID in ipairs(slotIDs) do
		EnchantCollectionUtil.slotSettings[slotID].point = {"CENTER", CalcPos(angles[index], radius)}
	end
end

local function SetEvenlySpacedOuterRing(slotIDs, radius)
	local count = #slotIDs
	if count == 0 then
		return
	end

	local step = 360 / count
	local startAngle = 90 - (step / 2)
	local angles = {}

	for index = 1, count do
		angles[index] = startAngle - ((index - 1) * step)
	end

	SetOuterRingAngles(slotIDs, angles, radius)
end

local function SetSlotQuality(slotIDs, quality)
	for _, slotID in ipairs(slotIDs) do
		EnchantCollectionUtil.slotSettings[slotID].quality = quality
	end
end

local function SetHeroSlotRequiredLevels(slotIDs, configPrefix)
	for unlockIndex, slotID in ipairs(slotIDs) do
		EnchantCollectionUtil.slotSettings[slotID].requiredLevel = C_Config.GetIntConfig(string.format(configPrefix, unlockIndex)) or 1
	end
end

local GetEnabledHeroSlotIDs

local function SetHeroFreepickSlotRequiredLevels()
	SetHeroSlotRequiredLevels(GetEnabledHeroSlotIDs(HERO_FREEPICK_EPIC_SLOT_IDS), "CONFIG_EPIC_RANDOM_ENCHANT_UNLOCK_LEVEL_%d")
	SetHeroSlotRequiredLevels(GetEnabledHeroSlotIDs(HERO_FREEPICK_RARE_SLOT_IDS), "CONFIG_RARE_RANDOM_ENCHANT_UNLOCK_LEVEL_%d")
	SetHeroSlotRequiredLevels(GetEnabledHeroSlotIDs(HERO_FREEPICK_GREEN_SLOT_IDS), "CONFIG_UNCOMMON_RANDOM_ENCHANT_UNLOCK_LEVEL_%d")
end

GetEnabledHeroSlotIDs = function(slotIDs)
	local enabledSlotIDs = {}

	for _, slotID in ipairs(slotIDs) do
		if EnchantCollectionUtil:IsHeroMysticEnchantSlotEnabled(slotID) then
			table.insert(enabledSlotIDs, slotID)
		end
	end

	return enabledSlotIDs
end

-- TODO: To local variable?
EnchantCollectionUtil.slotSettings = {
	{scale = 1.1,  quality = Enum.ItemQuality.Legendary, point = {"CENTER", 0, 0}, emptySlot = "EnchantSlotEmptyBig1", requiredLevel = 1},
	-- inner circle
	{scale = 1, quality = Enum.ItemQuality.Epic, point = {"CENTER", CalcPos(-30, RADIUS_1*0.8)}, emptySlot = "EnchantSlotEmptyBig1", requiredLevel = 1},
	{scale = 1, quality = Enum.ItemQuality.Epic, point = {"CENTER", CalcPos(-150, RADIUS_1*0.8)}, emptySlot = "EnchantSlotEmptyBig1", requiredLevel = 1},
	{scale = 1, quality = Enum.ItemQuality.Epic, point = {"CENTER", CalcPos(90, RADIUS_1*0.8)}, emptySlot = "EnchantSlotEmptyBig1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(-90, RADIUS_1)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(150, RADIUS_1)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(30, RADIUS_1)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},

	-- outer circle
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(DEFAULT_OUTER_RING_ANGLES[1], RADIUS_2)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(DEFAULT_OUTER_RING_ANGLES[2], RADIUS_2)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(DEFAULT_OUTER_RING_ANGLES[3], RADIUS_2)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(DEFAULT_OUTER_RING_ANGLES[4], RADIUS_2)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(DEFAULT_OUTER_RING_ANGLES[5], RADIUS_2)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(DEFAULT_OUTER_RING_ANGLES[6], RADIUS_2)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(DEFAULT_OUTER_RING_ANGLES[7], RADIUS_2)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(DEFAULT_OUTER_RING_ANGLES[8], RADIUS_2)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(DEFAULT_OUTER_RING_ANGLES[9], RADIUS_2)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
	{scale = 0.8, quality = 0, point = {"CENTER", CalcPos(DEFAULT_OUTER_RING_ANGLES[10], RADIUS_2)}, emptySlot = "EnchantSlotEmptyNormal1", requiredLevel = 1},
}

-------------------------------------------------------------------------------
--                              Game Mode Stuff                              --
-------------------------------------------------------------------------------
function EnchantCollectionUtil:ApplyHeroVisualRequiredLevels()
	for i = 1, #self.slotSettings do
		self.slotSettings[i].requiredLevel = 1
	end

	SetHeroSlotRequiredLevels(GetEnabledHeroSlotIDs({1}), "CONFIG_LEGENDARY_RANDOM_ENCHANT_UNLOCK_LEVEL_%d")
	SetHeroSlotRequiredLevels(GetEnabledHeroSlotIDs({2, 3, 4}), "CONFIG_EPIC_RANDOM_ENCHANT_UNLOCK_LEVEL_%d")
	SetHeroSlotRequiredLevels(GetEnabledHeroSlotIDs({5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}), "CONFIG_RARE_RANDOM_ENCHANT_UNLOCK_LEVEL_%d")
end

function EnchantCollectionUtil:ApplyHeroFreepickVisualRequiredLevels()
	for i = 1, #self.slotSettings do
		self.slotSettings[i].requiredLevel = 1
	end

	SetHeroFreepickSlotRequiredLevels()
end

function EnchantCollectionUtil:IsClassFusionEnabled()
	return C_Config.GetBoolConfig(CLASS_FUSION_CONFIG)
end

function EnchantCollectionUtil:IsHeroFreepickLayout()
	return self:IsClassFusionEnabled()
		and C_Player:IsHero()
		and not C_Player:IsCustomClass()
		and not C_GameMode:IsGameModeActive(
			Enum.GameMode.Random,
			Enum.GameMode.Ironman,
			Enum.GameMode.Survivalist,
			Enum.GameMode.Draft,
			Enum.GameMode.Resolute,
			Enum.GameMode.WildCard,
			Enum.GameMode.Felforged,
			Enum.GameMode.Nightmare,
			Enum.GameMode.FreepickRarities,
			Enum.GameMode.BuildDraft,
			Enum.GameMode.Crusader
		)
end

function EnchantCollectionUtil:ApplyHeroFreepickLayout()
	for i = 1, #self.slotSettings do
		self.slotSettings[i].hidden = true
		self.slotSettings[i].scale = i == 1 and 1.1 or 0.8
	end

	SetSlotQuality(HERO_FREEPICK_EPIC_SLOT_IDS, Enum.ItemQuality.Epic)
	SetSlotQuality(HERO_FREEPICK_RARE_SLOT_IDS, Enum.ItemQuality.Rare)
	SetSlotQuality(HERO_FREEPICK_GREEN_SLOT_IDS, Enum.ItemQuality.Uncommon)

	for _, slotID in ipairs(HERO_FREEPICK_EPIC_SLOT_IDS) do
		local slotSettings = self.slotSettings[slotID]
		slotSettings.hidden = not self:IsHeroMysticEnchantSlotEnabled(slotID)
		slotSettings.scale = 1.1

		if HERO_FREEPICK_EPIC_ANGLES[slotID] then
			slotSettings.point = {"CENTER", CalcPos(HERO_FREEPICK_EPIC_ANGLES[slotID], HERO_FREEPICK_EPIC_RADIUS)}
		end
	end

	for index, slotID in ipairs(HERO_FREEPICK_RARE_SLOT_IDS) do
		local slotSettings = self.slotSettings[slotID]
		slotSettings.hidden = not self:IsHeroMysticEnchantSlotEnabled(slotID)
		slotSettings.point = {"CENTER", CalcPos(HERO_FREEPICK_RARE_ANGLES[index], DRAFT_RADIUS_2)}
	end

	self.slotSettings[11].point = {"CENTER", CalcPos(-90, RADIUS_2 - 42)}
	self.slotSettings[11].scale = 1

	for index, slotID in ipairs(HERO_FREEPICK_GREEN_SLOT_IDS) do
		local slotSettings = self.slotSettings[slotID]
		slotSettings.hidden = not self:IsHeroMysticEnchantSlotEnabled(slotID)
		slotSettings.point = {"CENTER", CalcPos(HERO_FREEPICK_GREEN_ANGLES[index], DRAFT_RADIUS_2)}
	end

	self:ApplyHeroFreepickVisualRequiredLevels()
end

function EnchantCollectionUtil.OnGameModeChanged()
	for i = 1, #EnchantCollectionUtil.slotSettings do
		EnchantCollectionUtil.slotSettings[i].requiredLevel = 1
		EnchantCollectionUtil.slotSettings[i].hidden = false
		EnchantCollectionUtil.slotSettings[i].scale = i == 1 and 1.1 or i <= 4 and 1 or 0.8
		EnchantCollectionUtil.slotSettings[i].quality = i == 1 and Enum.ItemQuality.Legendary or i <= 4 and Enum.ItemQuality.Epic or 0
	end

	EnchantCollectionUtil.slotSettings[1].point = {"CENTER", 0, 0}
	EnchantCollectionUtil.slotSettings[2].point = {"CENTER", CalcPos(-30, RADIUS_1 * 0.8)}
	EnchantCollectionUtil.slotSettings[3].point = {"CENTER", CalcPos(-150, RADIUS_1 * 0.8)}
	EnchantCollectionUtil.slotSettings[4].point = {"CENTER", CalcPos(90, RADIUS_1 * 0.8)}
	EnchantCollectionUtil.slotSettings[5].point = {"CENTER", CalcPos(-90, RADIUS_1)}
	EnchantCollectionUtil.slotSettings[6].point = {"CENTER", CalcPos(150, RADIUS_1)}
	EnchantCollectionUtil.slotSettings[7].point = {"CENTER", CalcPos(30, RADIUS_1)}
	SetOuterRingAngles(OUTER_RING_SLOT_IDS, DEFAULT_OUTER_RING_ANGLES)

	if EnchantCollectionUtil:IsHeroFreepickLayout() then
		EnchantCollectionUtil:ApplyHeroFreepickLayout()
		return
	end

	if C_Player:IsDefaultClass() then
		EnchantCollectionUtil.slotSettings[1].quality = Enum.ItemQuality.Legendary
		EnchantCollectionUtil.slotSettings[1].requiredLevel = 30

		EnchantCollectionUtil.slotSettings[2].requiredLevel = 15

		EnchantCollectionUtil.slotSettings[3].requiredLevel = 25

		EnchantCollectionUtil.slotSettings[4].requiredLevel = 40

		EnchantCollectionUtil.slotSettings[5].quality = Enum.ItemQuality.Rare
		EnchantCollectionUtil.slotSettings[5].requiredLevel = 10
		EnchantCollectionUtil.slotSettings[5].point = {"CENTER", CalcPos(45, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[6].quality = Enum.ItemQuality.Rare
		EnchantCollectionUtil.slotSettings[6].requiredLevel = 45
		EnchantCollectionUtil.slotSettings[6].point = {"CENTER", CalcPos(0, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[7].quality = Enum.ItemQuality.Rare
		EnchantCollectionUtil.slotSettings[7].requiredLevel = 50
		EnchantCollectionUtil.slotSettings[7].point = {"CENTER", CalcPos(-45, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[8].quality = Enum.ItemQuality.Rare
		EnchantCollectionUtil.slotSettings[8].requiredLevel = 55
		EnchantCollectionUtil.slotSettings[8].point = {"CENTER", CalcPos(-135, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[9].quality = Enum.ItemQuality.Rare
		EnchantCollectionUtil.slotSettings[9].requiredLevel = 58
		EnchantCollectionUtil.slotSettings[9].point = {"CENTER", CalcPos(-180, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[10].quality = Enum.ItemQuality.Rare
		EnchantCollectionUtil.slotSettings[10].requiredLevel = 60
		EnchantCollectionUtil.slotSettings[10].point = {"CENTER", CalcPos(135, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[11].quality = Enum.ItemQuality.Vanity
		EnchantCollectionUtil.slotSettings[11].requiredLevel = 35
		EnchantCollectionUtil.slotSettings[11].point = {"CENTER", CalcPos(-90, RADIUS_2-42)}
		EnchantCollectionUtil.slotSettings[11].scale = 1

		EnchantCollectionUtil.slotSettings[12].hidden = true
		EnchantCollectionUtil.slotSettings[13].hidden = true
		EnchantCollectionUtil.slotSettings[14].hidden = true
		EnchantCollectionUtil.slotSettings[15].hidden = true
		EnchantCollectionUtil.slotSettings[16].hidden = true
		EnchantCollectionUtil.slotSettings[17].hidden = true
		return
	end

	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		-- Wildcard shares the default-class 11-slot layout (positions / required
		-- levels / hidden flags) but every slot is generic — any quality fits.
		EnchantCollectionUtil.slotSettings[1].quality = 0
		EnchantCollectionUtil.slotSettings[1].requiredLevel = 30

		EnchantCollectionUtil.slotSettings[2].quality = 0
		EnchantCollectionUtil.slotSettings[2].requiredLevel = 15

		EnchantCollectionUtil.slotSettings[3].quality = 0
		EnchantCollectionUtil.slotSettings[3].requiredLevel = 25

		EnchantCollectionUtil.slotSettings[4].quality = 0
		EnchantCollectionUtil.slotSettings[4].requiredLevel = 40

		EnchantCollectionUtil.slotSettings[5].quality = 0
		EnchantCollectionUtil.slotSettings[5].requiredLevel = 10
		EnchantCollectionUtil.slotSettings[5].point = {"CENTER", CalcPos(45, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[6].quality = 0
		EnchantCollectionUtil.slotSettings[6].requiredLevel = 45
		EnchantCollectionUtil.slotSettings[6].point = {"CENTER", CalcPos(0, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[7].quality = 0
		EnchantCollectionUtil.slotSettings[7].requiredLevel = 50
		EnchantCollectionUtil.slotSettings[7].point = {"CENTER", CalcPos(-45, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[8].quality = 0
		EnchantCollectionUtil.slotSettings[8].requiredLevel = 55
		EnchantCollectionUtil.slotSettings[8].point = {"CENTER", CalcPos(-135, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[9].quality = 0
		EnchantCollectionUtil.slotSettings[9].requiredLevel = 58
		EnchantCollectionUtil.slotSettings[9].point = {"CENTER", CalcPos(-180, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[10].quality = 0
		EnchantCollectionUtil.slotSettings[10].requiredLevel = 60
		EnchantCollectionUtil.slotSettings[10].point = {"CENTER", CalcPos(135, RADIUS_2)}

		EnchantCollectionUtil.slotSettings[11].quality = 0
		EnchantCollectionUtil.slotSettings[11].requiredLevel = 35
		EnchantCollectionUtil.slotSettings[11].point = {"CENTER", CalcPos(-90, RADIUS_2-42)}
		EnchantCollectionUtil.slotSettings[11].scale = 1

		EnchantCollectionUtil.slotSettings[12].hidden = true
		EnchantCollectionUtil.slotSettings[13].hidden = true
		EnchantCollectionUtil.slotSettings[14].hidden = true
		EnchantCollectionUtil.slotSettings[15].hidden = true
		EnchantCollectionUtil.slotSettings[16].hidden = true
		EnchantCollectionUtil.slotSettings[17].hidden = true
		return
	end

	for i = 1, #EnchantCollectionUtil.slotSettings do
		EnchantCollectionUtil.slotSettings[i].hidden = false
	end

	if C_Player:IsHero() then
		for i = 1, #EnchantCollectionUtil.slotSettings do
			EnchantCollectionUtil.slotSettings[i].hidden = not EnchantCollectionUtil:IsHeroMysticEnchantSlotEnabled(i)
		end
	end

	EnchantCollectionUtil.slotSettings[1].quality = Enum.ItemQuality.Legendary
	EnchantCollectionUtil.slotSettings[2].quality = Enum.ItemQuality.Epic
	EnchantCollectionUtil.slotSettings[3].quality = Enum.ItemQuality.Epic
	EnchantCollectionUtil.slotSettings[4].quality = Enum.ItemQuality.Epic

	if C_Player:IsHero() then
		EnchantCollectionUtil:ApplyHeroVisualRequiredLevels()
	end

	if C_Player:IsHero() or C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
		SetEvenlySpacedOuterRing(GetEnabledHeroSlotIDs(OUTER_RING_SLOT_IDS), DRAFT_RADIUS_2)
	end
end

EnchantCollectionUtil.OnGameModeChangeHandle = C_GameMode:RegisterCallbackWithHandle("OnGameModeChanged",  EnchantCollectionUtil.OnGameModeChanged)

function EnchantCollectionUtil:IsHeroMysticEnchantSlotEnabled(slot)
	if not C_Player:IsHero() then
		return true
	end

	return (C_Config.GetIntConfig(string.format("CONFIG_HERO_RANDOM_ENCHANT_SLOT_%d_ENABLED", slot)) or 1) ~= 0
end

local HeroUnlockConfigByQuality = {
	[Enum.ItemQuality.Uncommon] = {
		maxConfig = "CONFIG_MAX_UNCOMMON_RANDOM_ENCHANTS",
		unlockConfigPrefix = "CONFIG_UNCOMMON_RANDOM_ENCHANT_UNLOCK_LEVEL_%d",
		unlockConfigCount = #HERO_FREEPICK_GREEN_SLOT_IDS,
	},
	[Enum.ItemQuality.Rare] = {
		maxConfig = "CONFIG_MAX_RARE_RANDOM_ENCHANTS",
		unlockConfigPrefix = "CONFIG_RARE_RANDOM_ENCHANT_UNLOCK_LEVEL_%d",
		unlockConfigCount = #HERO_FREEPICK_RARE_SLOT_IDS,
	},
	[Enum.ItemQuality.Epic] = {
		maxConfig = "CONFIG_MAX_EPIC_RANDOM_ENCHANTS",
		unlockConfigPrefix = "CONFIG_EPIC_RANDOM_ENCHANT_UNLOCK_LEVEL_%d",
		unlockConfigCount = #HERO_FREEPICK_EPIC_SLOT_IDS,
	},
	[Enum.ItemQuality.Legendary] = {
		maxConfig = "CONFIG_MAX_LEGENDARY_RANDOM_ENCHANTS",
		unlockConfigPrefix = "CONFIG_LEGENDARY_RANDOM_ENCHANT_UNLOCK_LEVEL_%d",
	},
	[Enum.ItemQuality.Vanity] = {
		maxConfig = "CONFIG_MAX_ARTIFACT_RANDOM_ENCHANTS",
		unlockConfigPrefix = "CONFIG_ARTIFACT_RANDOM_ENCHANT_UNLOCK_LEVEL_%d",
	},
}

function EnchantCollectionUtil:GetHeroUnlockConfigForQuality(quality)
	return HeroUnlockConfigByQuality[quality]
end

function EnchantCollectionUtil:GetCurrentSlotQuality(slot)
	local spellID = self:GetSlotData(slot)
	if not spellID or spellID == 0 then
		return
	end

	local enchantInfo = C_MysticEnchant.GetEnchantInfoBySpell(spellID)
	if not enchantInfo then
		return
	end

	return self:GetQualityFromQualityName(enchantInfo.Quality)
end

function EnchantCollectionUtil:GetAppliedEnchantCountForQuality(quality)
	local count = 0

	for slot = 1, self.maxSlots do
		if self:GetCurrentSlotQuality(slot) == quality then
			count = count + 1
		end
	end

	return count
end

function EnchantCollectionUtil:GetMaxUnlockedHeroEnchantsForQuality(quality)
	if not C_Player:IsHero() then
		return
	end

	local config = self:GetHeroUnlockConfigForQuality(quality)
	if not config then
		return
	end

	local maxUnlocked = C_Config.GetIntConfig(config.maxConfig) or 0
	if self:IsHeroFreepickLayout() then
		local numUnlocked = 0
		for i = 1, config.unlockConfigCount or maxUnlocked do
			local unlockLevel = C_Config.GetIntConfig(string.format(config.unlockConfigPrefix, i))
			if not unlockLevel or C_Player:GetLevel() >= unlockLevel then
				numUnlocked = numUnlocked + 1
			end
		end

		return math.min(numUnlocked, maxUnlocked)
	end

	for i = 1, maxUnlocked do
		local unlockLevel = C_Config.GetIntConfig(string.format(config.unlockConfigPrefix, i))
		if unlockLevel and C_Player:GetLevel() < unlockLevel then
			return i - 1
		end
	end

	return maxUnlocked
end

function EnchantCollectionUtil:GetNextUnlockLevelForHeroQuality(quality)
	if not C_Player:IsHero() then
		return
	end

	local config = self:GetHeroUnlockConfigForQuality(quality)
	if not config then
		return
	end

	local maxUnlocked = C_Config.GetIntConfig(config.maxConfig) or 0
	local currentUnlocked = self:GetMaxUnlockedHeroEnchantsForQuality(quality) or 0
	if currentUnlocked >= maxUnlocked then
		return
	end
	if self:IsHeroFreepickLayout() then
		local nextUnlockLevel
		for i = 1, config.unlockConfigCount or maxUnlocked do
			local unlockLevel = C_Config.GetIntConfig(string.format(config.unlockConfigPrefix, i))
			if unlockLevel and C_Player:GetLevel() < unlockLevel and (not nextUnlockLevel or unlockLevel < nextUnlockLevel) then
				nextUnlockLevel = unlockLevel
			end
		end

		return nextUnlockLevel
	end

	return C_Config.GetIntConfig(string.format(config.unlockConfigPrefix, currentUnlocked + 1))
end

function EnchantCollectionUtil:GetRequiredLevelForHeroSlot(slot, quality)
	if not C_Player:IsHero() then
		return
	end

	local config = self:GetHeroUnlockConfigForQuality(quality)
	if not config then
		return
	end

	if self:GetCurrentSlotQuality(slot) == quality then
		return
	end

	local currentUnlocked = self:GetMaxUnlockedHeroEnchantsForQuality(quality) or 0
	local appliedCount = self:GetAppliedEnchantCountForQuality(quality)
	if appliedCount < currentUnlocked then
		return
	end

	return self:GetNextUnlockLevelForHeroQuality(quality)
end

-------------------------------------------------------------------------------
--                              Fake Slot Stuff                              --
-------------------------------------------------------------------------------
EnchantCollectionUtil.defaultSlotMap = {}
EnchantCollectionUtil.slotMap = {}

for i = 1, #EnchantCollectionUtil.slotSettings do
	EnchantCollectionUtil.defaultSlotMap[i] = i
	EnchantCollectionUtil.slotMap[i] = i
end

function EnchantCollectionUtil:GetSlotMapLayout()
	if self:IsHeroFreepickLayout() then
		return HERO_FREEPICK_SLOT_MAP_LAYOUT
	end
end

function EnchantCollectionUtil:IsHeroFreepickSlotMapValid(slotMap)
	if not slotMap then
		return false
	end

	local usedRealSlots = {}
	for visualSlotID = 1, #self.slotSettings do
		local realSlotID = slotMap[visualSlotID]
		if type(realSlotID) ~= "number" or realSlotID < 1 or realSlotID > #self.slotSettings or usedRealSlots[realSlotID] then
			return false
		end

		usedRealSlots[realSlotID] = true
	end

	for _, visualSlotID in ipairs(HERO_FREEPICK_VISIBLE_SLOT_IDS) do
		local realSlotID = slotMap[visualSlotID]
		if realSlotID < HERO_FREEPICK_REAL_SLOT_IDS[1] or realSlotID > HERO_FREEPICK_REAL_SLOT_IDS[#HERO_FREEPICK_REAL_SLOT_IDS] then
			return false
		end
	end

	return true
end

function EnchantCollectionUtil:GetHeroFreepickSlotMap(slotData)
	local newMap = {unpack(self.defaultSlotMap)}
	local availableRealSlots = {unpack(HERO_FREEPICK_REAL_SLOT_IDS)}

	local function TakeRealSlotForQuality(quality)
		for index, realSlotID in ipairs(availableRealSlots) do
			local enchantInfo = C_MysticEnchant.GetEnchantInfoBySpell(slotData[realSlotID])
			if enchantInfo and EnchantCollectionUtil:GetQualityFromQualityName(enchantInfo.Quality) == quality then
				table.remove(availableRealSlots, index)
				return realSlotID
			end
		end

		for index, realSlotID in ipairs(availableRealSlots) do
			if not slotData[realSlotID] or slotData[realSlotID] == 0 then
				table.remove(availableRealSlots, index)
				return realSlotID
			end
		end

		return table.remove(availableRealSlots, 1)
	end

	for _, visualSlotID in ipairs(HERO_FREEPICK_VISIBLE_SLOT_IDS) do
		newMap[visualSlotID] = TakeRealSlotForQuality(self.slotSettings[visualSlotID].quality)
	end

	-- These visual positions are hidden in the freepick layout. Keeping the two
	-- legacy API slots here makes the complete map a stable 1..17 permutation.
	newMap[16] = 1
	newMap[17] = 17

	return newMap
end

function EnchantCollectionUtil:GetFakePositionMapDefaultClass(slotData)
	local newMap = {unpack(self.defaultSlotMap)}
	local finalMap = {}

	local qualityMax = {}
	local slotDataByQuality = {}

	local emptySlots = {}

	for slotID, slotData in pairs(self.slotSettings) do
		if not slotData.hidden then
			qualityMax[slotData.quality] = (qualityMax[slotData.quality] or 0) + 1
		end
	end
	
	for i = 1, #slotData do
		local REData = C_MysticEnchant.GetEnchantInfoBySpell(slotData[i])
		local quality = REData and EnchantCollectionUtil:GetQualityFromQualityName(REData.Quality)

		if quality then
			slotDataByQuality[quality] = slotDataByQuality[quality] or {}
			table.insert(slotDataByQuality[quality], i)

			local qualityTotal = #slotDataByQuality[quality]

			if not qualityMax[quality] or qualityTotal > qualityMax[quality] then
				dprint("EnchantCollectionUtil: Map contains wrong data, don't sort.")
				dprint("quality: "..quality.." x"..qualityTotal.." comp with: "..(qualityMax[quality] or "NO QUALITY DATA MAX"))
				return newMap
			end
		else
			table.insert(emptySlots, i)
		end
	end

	for slotID, slotData in pairs(self.slotSettings) do
		if slotData.hidden then
			finalMap[slotID] = slotID
		else
			local referenceQuality = self.slotSettings[slotID].quality

			if slotDataByQuality[referenceQuality] and (next(slotDataByQuality[referenceQuality])) then
				local realSlotID = slotDataByQuality[referenceQuality][1]

				finalMap[slotID] = realSlotID

				table.remove(slotDataByQuality[referenceQuality], 1)
			end
		end
	end

	-- fill the rest
	for slotID, slotData in pairs(self.slotSettings) do
		if not finalMap[slotID] then
			finalMap[slotID] = emptySlots[1]
			table.remove(emptySlots, 1)
		end
	end

	return finalMap
end


function EnchantCollectionUtil:GetFakePositionMap(slotData)
	if self:IsHeroFreepickLayout() then
		return self:GetHeroFreepickSlotMap(slotData)
	end

	if C_Player:IsDefaultClass() then
		return self:GetFakePositionMapDefaultClass(slotData)
	end

	local newMap = {unpack(self.defaultSlotMap)}

	local leg = {}
	local epic = {}
	local rare = {}
	local normal = {}
	local empty = {}

	local MAX_LEG = 1
	local MAX_EPIC = C_Player:IsDefaultClass() and 3 or 3
	local MAX_RARE = C_Player:IsDefaultClass() and 6 or nil

	local firstAvailableSlot = 2 -- any rarity can start from slot 2

	for i = 1, #slotData do
		local REData = C_MysticEnchant.GetEnchantInfoBySpell(slotData[i])
		local quality = REData and EnchantCollectionUtil:GetQualityFromQualityName(REData.Quality)

		if not(quality) then
			table.insert(empty, i)
		elseif (quality == Enum.ItemQuality.Legendary) then
			table.insert(leg, i)
		elseif (quality == Enum.ItemQuality.Epic) then
			table.insert(epic, i)
		elseif MAX_RARE and (quality == Enum.ItemQuality.Rare) then
			table.insert(rare, i)
		else
			table.insert(normal, i)
		end
	end

	if (#leg > MAX_LEG) or (#epic > MAX_EPIC) or (MAX_RARE and (#rare > MAX_RARE)) then
		dprint("EnchantCollectionUtil: Map contains wrong data, don't sort.")
		return newMap
	end

	if next(leg) then
		for i = 1, #leg do -- legendary always go to slot 1. Or leave slot 1 empty
			newMap[1] = leg[i]
		end
	else
		newMap[1] = next(empty) and empty[1]
		table.remove(empty, 1)
	end

	if next(epic) then
		for i = 1, #epic do
			newMap[firstAvailableSlot] = epic[i]
			firstAvailableSlot = firstAvailableSlot + 1
		end
	end

	if MAX_RARE and next(rare) then
		for i = 1, #rare do
			newMap[firstAvailableSlot] = rare[i]
			firstAvailableSlot = firstAvailableSlot + 1
		end
	end

	if next(normal) then
		for i = 1, #normal do
			newMap[firstAvailableSlot] = normal[i]
			firstAvailableSlot = firstAvailableSlot + 1
		end
	end

	if next(empty) then
		for i = 1, #empty do
			newMap[firstAvailableSlot] = empty[i]
			firstAvailableSlot = firstAvailableSlot + 1
		end
	end

	return newMap
end

function EnchantCollectionUtil:GetSlotMapForEnchants(slotData)
	if self:IsHeroFreepickLayout() then
		return self:GetHeroFreepickSlotMap(slotData)
	end

	local needsFix = false

	for i = 1, #slotData do
		local REData = C_MysticEnchant.GetEnchantInfoBySpell(slotData[i]) or {Quality = "RE_QUALITY_UNCOMMON"}
		local quality = EnchantCollectionUtil:GetQualityFromQualityName(REData.Quality)

		if not(self:CanApplyQualityToSlot(i, quality)) then
			needsFix = true
		end
	end

	if not(needsFix) then
		return self.defaultSlotMap
	else
		return self:GetFakePositionMap(slotData)
	end
end

-- this should really happen but if so - purge slot map and re-create it
function EnchantCollectionUtil:CheckSlotMap()
	if self:IsHeroFreepickLayout() and not self:IsHeroFreepickSlotMapValid(self.slotMap) then
		dprint("EnchantCollectionUtil: Hero freepick slot map has an invalid real-slot domain or duplicate.")
		return false
	end

	local slotData = {}
	
	for i = 1, #self.slotSettings do
		slotData[i] = self:GetSlotData(i)
	end

	local needsFix = false

	for i = 1, #slotData do
		local REData = C_MysticEnchant.GetEnchantInfoBySpell(slotData[i])
		local quality = REData and EnchantCollectionUtil:GetQualityFromQualityName(REData.Quality)

		local isSupportedHeroFreepickQuality = quality == Enum.ItemQuality.Uncommon or quality == Enum.ItemQuality.Rare or quality == Enum.ItemQuality.Epic
		if REData and (not self:IsHeroFreepickLayout() or isSupportedHeroFreepickQuality) and not(self:CanApplyQualityToSlot(i, quality)) then
			dprint("EnchantCollectionUtil: Can not apply slot "..i.." quality "..quality.." spellID: "..slotData[i])
			needsFix = true
		end
	end

	if needsFix then
		dprint("EnchantCollectionUtil: SLOT MAP NEEDS UPDATE")
		return false
	else
		dprint("EnchantCollectionUtil: SLOT MAP IS FINE")
		return true
	end
end

function EnchantCollectionUtil:Init()
	local activePresetIndex = MysticEnchantManagerUtil.GetActivePreset()
	local slotMap, slotMapLayout = MysticEnchantManagerUtil.GetPresetSlotMap(activePresetIndex)
	local currentSlotMapLayout = self:GetSlotMapLayout()
	if slotMapLayout ~= currentSlotMapLayout then
		slotMap = nil
	end
  	
  	-- always have self.slotMap self:GetSlotData recieves values according to self.slotMap
	if not(slotMap) then
		local slotData = {}
		
		for i = 1, #self.slotSettings do
			if self:IsHeroFreepickLayout() then
				slotData[i] = C_MysticEnchant.GetAppliedEnchant("player", i)
			else
				slotData[i] = self:GetSlotData(i)
			end
		end

		dprint("EnchantCollectionUtil: Generating new map for spec "..activePresetIndex)

		self.slotMap = self:GetSlotMapForEnchants(slotData)

		MysticEnchantManagerUtil.UpdatePresetSlotMap(activePresetIndex, self.slotMap, currentSlotMapLayout)
	else
		self.slotMap = slotMap
		-- edit real slot map to check it
		if not(self:CheckSlotMap()) then
			self.slotMap = {unpack(self.defaultSlotMap)}
			MysticEnchantManagerUtil.UpdatePresetSlotMap(activePresetIndex, nil, nil)
			self:Init()
		end
	end

	C_Hook:SendEvent("MYSTIC_ENCHANT_SLOT_MAP_REFRESH")
end

function EnchantCollectionUtil:GetRealSlotID(slot)
	return self.slotMap[slot]
end

function EnchantCollectionUtil:GetFakeSlotID(slot)
	for i = 1, self.maxCollectionButtons do
		if (self.slotMap[i] == slot) then
			return i
		end
	end
end

-------------------------------------------------------------------------------
--                                 Main logic                                --
-------------------------------------------------------------------------------
function EnchantCollectionUtil:MYSTIC_ENCHANT_LEARNED(spellID)
	if (EnchantCollection and EnchantCollection:IsVisible()) then
		return
	end

	if Collections then Collections:GoToTab(Collections.Tabs.MysticEnchants) end

	if (EnchantCollection) then
		EnchantCollection:MYSTIC_ENCHANT_LEARNED(spellID)
	else
		Timer.After(0.5, function() C_Hook:SendEvent("MYSTIC_ENCHANT_LEARNED", spellID) end)
	end
end

function EnchantCollectionUtil:MYSTIC_ENCHANT_PROGRESS_UPDATE(progress, level)
	if (EnchantCollection and EnchantCollection:IsVisible()) then
		return
	end

	if Collections then Collections:GoToTab(Collections.Tabs.MysticEnchants) end

	if (EnchantCollection) then
		EnchantCollection:MYSTIC_ENCHANT_PROGRESS_UPDATE(progress, level)
	else
		Timer.After(0.5, function() C_Hook:SendEvent("MYSTIC_ENCHANT_PROGRESS_UPDATE", progress, level) end)
	end
end
function EnchantCollectionUtil:MYSTIC_ALTAR_USED()
	if Collections then Collections:GoToTab(Collections.Tabs.MysticEnchants) end
end

function EnchantCollectionUtil:MYSTIC_SCROLL_USED(itemID)
	if Collections then Collections:GoToTab(Collections.Tabs.MysticEnchants) end
	
	if (EnchantCollection) then
		EnchantCollection:MYSTIC_SCROLL_USED(itemID)
	else
		Timer.After(0.5, function() C_Hook:SendEvent("MYSTIC_SCROLL_USED", itemID) end)
	end
end

function EnchantCollectionUtil:MYSTIC_ALTAR_CLOSED()
	if Collections and Collections:IsVisible() then
		if Collections:GetCurrentTabID() == Collections.Tabs.MysticEnchants then
			HideUIPanel(Collections)
		end
	end
end

function EnchantCollectionUtil:MYSTIC_ENCHANT_UNLOCK_PRESET_USED()
	if Collections then Collections:GoToTab(Collections.Tabs.MysticEnchants) end

	if EnchantCollection then
		EnchantCollection:MYSTIC_ENCHANT_UNLOCK_PRESET_USED()
	end
end

function EnchantCollectionUtil:HandleError(func, funcArgs, success, errorStr, ...)
	--dprint(errorStr)
	--DevTools_Dump(funcArgs)

	if success then
		return false
	end

	if type(errorStr) ~= "string" or string.isNilOrEmpty(errorStr) then
		return false
	end

	if string.find(errorStr, "_OK$") then
		C_Logger.Error("EnchantCollectionUtil:HandleError: Error string %s ends with _OK but success is false.", errorStr)
		return false
	end

	if (self.specialErrors[errorStr]) then
		C_Hook:SendEvent("MYSTIC_ALTAR_CLOSED")
	end

	local error = _G[errorStr] or errorStr

	if errorStr == "RE_COLLECTION_REFORGE_NO_MONEY" then
		if func == "CanCollectionReforgeSlot" then
			local slotID, spellID = unpack(funcArgs)
			if spellID then
				local tokenCost, moneyCost = C_MysticEnchant.GetCollectionReforgeSlotCost(spellID)
				error = error:format(tokenCost, BreakUpLargeMoneyString(moneyCost, true))
			end
		elseif func == "CanCollectionReforgeItem" then
			local itemID, spellID = unpack(funcArgs)
			if spellID then
				local tokenCost, moneyCost = C_MysticEnchant.GetCollectionReforgeItemCost(spellID)
				error = error:format(tokenCost, BreakUpLargeMoneyString(moneyCost, true))
			end
		else
			local _, _, totalRequiredMoney, totalRequiredTokens = ...
			error = error:format(totalRequiredTokens, BreakUpLargeMoneyString(totalRequiredMoney, true))
		end
	end
	SendSystemMessage("|cffFF0000"..error.."|r")
	UIErrorsFrame:AddMessage(error, 1, 0, 0)
	
	return true
end

function EnchantCollectionUtil:HandleCheck(checkFunc, ...)
	if self:HandleError(checkFunc, {...}, C_MysticEnchant[checkFunc](...)) then
		return false
	end

	return true
end

function EnchantCollectionUtil:AttemptOperation(func, checkFunc, ...)
	dprint("EnchantCollectionUtil:AttemptOperation "..func..", "..checkFunc)

	if self:HandleCheck(checkFunc, ...) then
		C_MysticEnchant[func](...)
		return true
	end

	return false
end

function EnchantCollectionUtil:GetAltar()
	return C_MysticEnchant.HasNearbyMysticAltar()
end

function EnchantCollectionUtil:GetQualityFromQualityName(quality)
	return Enum.EnchantQualityEnum[quality] or Enum.ItemQuality.Uncommon
end

function EnchantCollectionUtil:GetSlotSettings(id)
	return self.slotSettings[id]
end

function EnchantCollectionUtil:GetBorderStyleForSlot(slot)
	local state = slot:GetState() or Enum.ECSlotStates.Unknown
	local quality = slot:GetQuality()

	if (state == Enum.ECSlotStates.Known) then
		return Enum.ECSlotBorderStylesKnown[quality] or "EnchantSlotBorderKnownEpic"
	elseif (state == Enum.ECSlotStates.Unknown) then
		return Enum.ECSlotBorderStylesUnKnown[quality] or "EnchantSlotBorderUnknownNormal"
	end

	return "EnchantSlotBorderUnknownNormal"
end

function EnchantCollectionUtil:GetBorderStyleAnimated(slot)
	local quality = slot:GetQuality()

	return Enum.ECSlotBorderStylesAnimated[quality] or "EnchantSlotBorderAnimatedNormal"
end


function EnchantCollectionUtil:GetQuestionMarkStyle(slot)
	local quality = slot:GetQuality()
	return Enum.ECQuestionMarkStyles[quality] or "EnchantSlotQuestionMarkNormal"
end

-- TODO: Maybe worth replacing later via pre-calculated texture coordinates
function EnchantCollectionUtil:SetTexRotationWithCoord(region, radians, L, R, T, B)
	radians = (math.pi / 4) - radians
	local Cx, Cy = (L + R) / 2, (T + B) / 2
	local Z = math.sqrt((R - Cx)^2 + (B - Cy)^2)
	local Zcos, Zsin = Z * math.cos(radians), Z * math.sin(radians)

	region:SetTexCoord(Cx - Zsin, Cy - Zcos, Cx - Zcos, Cy + Zsin, Cx + Zcos, Cy - Zsin, Cx + Zsin, Cy + Zcos)
end

function EnchantCollectionUtil:IsItemDataPosAndEntryEqual(itemDataA, itemDataB)
	if not(itemDataA.Entry == itemDataB.Entry) then
		return false
	end

	if not(itemDataA.Bag == itemDataB.Bag) then
		return false
	end

	if not(itemDataA.Slot == itemDataB.Slot) then
		return false
	end

	return true
end

function EnchantCollectionUtil:IsItemGUIDLowEqual(itemDataA, itemDataB)
	if not(itemDataA.Entry == itemDataB.Entry) then
		return false
	end

	if not(itemDataA.Guid == itemDataB.Guid) then
		return false
	end

	return true
end

function EnchantCollectionUtil:GetTempSlotData(slot)
	for i, tempEnchData in pairs(self.tempSlotData) do
		if ((tempEnchData.RESlot == slot) or (tempEnchData.Slot == slot)) and tempEnchData.Enchant then
			return tempEnchData.Enchant.SpellID
		end
	end
end

function EnchantCollectionUtil:GetSlotData(slot)
	slot = self:GetRealSlotID(slot)

	return self:GetTempSlotData(slot) or C_MysticEnchant.GetAppliedEnchant("player", slot)
end

function EnchantCollectionUtil:RefreshTempData()
	self.tempSlotData = C_MysticEnchant.GetApplyChanges()

	if not(self:HasStagedChanges()) then
		self.tempSlotData = C_MysticEnchant.GetCollectionReforgeChanges()
	end
end

function EnchantCollectionUtil:HasRequiredLevelForSlot(slot, quality)
	local reqLevel = self.slotSettings[slot].requiredLevel or 1

	if C_Player:IsHero() and quality and not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) and not self:IsHeroFreepickLayout() then
		reqLevel = self:GetRequiredLevelForHeroSlot(slot, quality) or reqLevel
	end

	if C_Player:GetLevel() < reqLevel then
		return false, reqLevel
	end

	return true, reqLevel
end

function EnchantCollectionUtil:CanApplyQualityToSlot(slot, quality)
	if not self.slotSettings[slot] or self.slotSettings[slot].hidden then
		return false
	end

	if C_Player:IsHero() and not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) and not self:IsHeroMysticEnchantSlotEnabled(slot) then
		return false
	end

	if self:IsHeroFreepickLayout() then
		return quality == self.slotSettings[slot].quality
	end

	-- Wildcard uses the default-class 11-slot layout but every slot is generic,
	-- so any quality fits anywhere the level gate allows.
	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		return true
	end

	-- Legendary can be applied only to legendary, epic only to epic and rare/uncommon to anywhere besides legendary.

	-- rare only to rare for og classes
	if ((quality == Enum.ItemQuality.Legendary) or (quality == Enum.ItemQuality.Epic) or (quality == Enum.ItemQuality.Vanity) or (C_Player:IsDefaultClass() and (quality == Enum.ItemQuality.Rare))) and (quality ~= self.slotSettings[slot].quality) then
		return false
	end

	-- legendary to legendary only, artifact to artifact
	if (quality ~= self.slotSettings[slot].quality) and ( (self.slotSettings[slot].quality == Enum.ItemQuality.Vanity) or (self.slotSettings[slot].quality == Enum.ItemQuality.Vanity) ) then
		return false
	end

	return true
end

function EnchantCollectionUtil:ApplyScrollEnchant(slot, itemData)
	if not(itemData) then
		return false, "Item data not found for scroll"
	end

	local item = Item:CreateFromID(itemData.Entry)

	if not(self.slotSettings[slot]) then
		return false, "Such slot does not exist "..slot
	end

	if not(self:CanApplyQualityToSlot(slot, item:GetQuality())) then
		return false, ENCHANT_ERROR_SCROLL_POS
	end

	slot = self:GetRealSlotID(slot)

	local result = EnchantCollectionUtil:AttemptOperation("ApplySlot", "CanApplySlot", slot, itemData.Guid)

	self:RefreshTempData()

	C_Hook:SendEvent("MYSTIC_ENCHANT_SLOT_UPDATE", slot)
	return result
end

function EnchantCollectionUtil:ApplyCollectionEnchant(slot, spellID)
	local REData = C_MysticEnchant.GetEnchantInfoBySpell(spellID)

	if not(REData) then
		return false, "REData not found for enchant"
	end

	if not(self.slotSettings[slot]) then
		return false, "Such slot does not exist "..slot
	end

	local quality = EnchantCollectionUtil:GetQualityFromQualityName(REData.Quality)

	if not(self:CanApplyQualityToSlot(slot, quality)) then
		return false, ENCHANT_ERROR_SCROLL_POS
	end

	slot = self:GetRealSlotID(slot)

	local result = EnchantCollectionUtil:AttemptOperation("CollectionReforgeSlot", "CanCollectionReforgeSlot", slot, spellID)

	self:RefreshTempData()

	C_Hook:SendEvent("MYSTIC_ENCHANT_SLOT_UPDATE", slot)
	return result
end

-- TODO: Not used atm
function EnchantCollectionUtil:RefundEnchant(slot)
	if not(self.slotSettings[slot]) then
		return false, "Such slot does not exist "..slot
	end

	slot = self:GetRealSlotID(slot)

	if (self:GetTempSlotData(slot)) then
		C_MysticEnchant.UndoApply(slot)
		C_MysticEnchant.UndoCollectionReforge(slot)
		
		self:RefreshTempData()

		C_Hook:SendEvent("MYSTIC_ENCHANT_SLOT_UPDATE", slot)
		return true
	else
		return false
	end
end

function EnchantCollectionUtil:HasStagedChanges()
	local hasChanges = false
	local isOverwritingUncollected = false
	local appliedEnchantID, appliedEnchant
	for _, tempEnchData in pairs(self.tempSlotData) do
		if tempEnchData.Enchant then
			hasChanges = true
			appliedEnchantID = C_MysticEnchant.GetAppliedEnchant("player", tempEnchData.Slot)
			if appliedEnchantID then
				appliedEnchant = C_MysticEnchant.GetEnchantInfoBySpell(appliedEnchantID)
				if appliedEnchant and not appliedEnchant.Known then
					isOverwritingUncollected = true
				end
			end
		end
	end

	return hasChanges, isOverwritingUncollected
end

function EnchantCollectionUtil:IsCollectionReforge()
	local hasChanges = false
	local isOverwritingUncollected = false
	local appliedEnchantID, appliedEnchant
	for _, tempEnchData in pairs(self.tempSlotData) do
		if tempEnchData.Enchant and tempEnchData.Slot then
			hasChanges = true
			appliedEnchantID = C_MysticEnchant.GetAppliedEnchant("player", tempEnchData.Slot)
			if appliedEnchantID then
				appliedEnchant = C_MysticEnchant.GetEnchantInfoBySpell(appliedEnchantID)
				if appliedEnchant and not appliedEnchant.Known then
					isOverwritingUncollected = true
				end
			end
		end
	end

	return hasChanges, isOverwritingUncollected
end

function EnchantCollectionUtil:ClearStagedChanges()
	for _, tempEnchData in pairs(self.tempSlotData) do
		local slot = nil
		if (tempEnchData.RESlot) then
			slot = tempEnchData.RESlot
			C_MysticEnchant.UndoApply(slot)
		elseif (tempEnchData.Slot) then
			slot = tempEnchData.Slot
			C_MysticEnchant.UndoCollectionReforge(slot)
		end

		self:RefreshTempData()

		C_Hook:SendEvent("MYSTIC_ENCHANT_SLOT_UPDATE", slot)
	end
end

function EnchantCollectionUtil:Apply()
	dprint("EnchantCollectionUtil:Apply")

	if (self:IsCollectionReforge()) then
		local result = EnchantCollectionUtil:AttemptOperation("SaveCollectionReforge", "CanSaveCollectionReforge")

		if (result) then
			self:ClearStagedChanges()
			return true
		end

		return false
	end

	local result = EnchantCollectionUtil:AttemptOperation("SaveApply", "CanSaveApply")

	if (result) then
		self:ClearStagedChanges()
		return true
	end

	return false
end

-- TODO: Move costs to its own util probably
function EnchantCollectionUtil:GetCollectionReforgeSlotCost(spellID)
	local tokenCost, moneyCost = C_MysticEnchant.GetCollectionReforgeSlotCost(spellID)

	local cost = { 
		[Enum.UnlearnCost.MarksOfAscension] = tokenCost or 0,
		[Enum.UnlearnCost.Gold] = moneyCost or 0 
	}

	return cost
end

function EnchantCollectionUtil:GetCollectionReforgeItemCost(spellID)
	local _, moneyCost = C_MysticEnchant.GetCollectionReforgeItemCost(spellID)

	local cost = { 
		[Enum.UnlearnCost.Gold] = moneyCost or 0 
	}
	
	local items = {
	}

	local indexTable = {Enum.UnlearnCost.Gold}
	local finalCost = {}

	CostUtil:FinalazeCost(items, cost, finalCost, indexTable)

	return finalCost
end

function EnchantCollectionUtil:GetCollectionReforgeSlotCostWithAppliedChanges(spellID)
	local tokenCost, moneyCost = C_MysticEnchant.GetCollectionReforgeSlotCost(spellID)

	local costOfChanges = EnchantCollectionUtil:CalculateCollectionReforgeCost()

	local items = {
		[Enum.UnlearnCost.MarksOfAscension] = GetItemCount(ItemData.MARK_OF_ASCENSION),
	}

	if costOfChanges and (costOfChanges[Enum.UnlearnCost.MarksOfAscension]) then
		if (items[Enum.UnlearnCost.MarksOfAscension] - costOfChanges[Enum.UnlearnCost.MarksOfAscension] - tokenCost) < 0 then
			return {[Enum.UnlearnCost.Gold] = moneyCost}
		end
	elseif (items[Enum.UnlearnCost.MarksOfAscension] - tokenCost) < 0 then
		return {[Enum.UnlearnCost.Gold] = moneyCost}
	end

	return {[Enum.UnlearnCost.MarksOfAscension] = tokenCost}
end

function EnchantCollectionUtil:CalculateCollectionReforgeCost()
	if not(self:IsCollectionReforge()) then
		return
	end

	local items = {
		[Enum.UnlearnCost.MarksOfAscension] = GetItemCount(ItemData.MARK_OF_ASCENSION),
	}

	local indexTable = {Enum.UnlearnCost.MarksOfAscension, Enum.UnlearnCost.Gold}
	local finalCost = {}

	for _, tempEnchData in pairs(self.tempSlotData) do
		if tempEnchData.Enchant then
			CostUtil:FinalazeCost(items, self:GetCollectionReforgeSlotCost(tempEnchData.Enchant.SpellID), finalCost, indexTable)
		end
	end

	return finalCost
end

function EnchantCollectionUtil:CalculateExtractCost(SpellID)
	local items = {
		[Enum.UnlearnCost.MysticExtract] = GetItemCount(ItemData.MYSTIC_EXTRACT),
		[Enum.UnlearnCost.MarksOfAscension] = GetItemCount(ItemData.MARK_OF_ASCENSION),
	}

	local indexTable = {Enum.UnlearnCost.MysticExtract, Enum.UnlearnCost.MarksOfAscension}
	local finalCost = {}

	local tokenCost, markCost = C_MysticEnchant.GetDisenchantCost(SpellID, MysticEnchantUtil.NeedsToPurchaseExtract())

	local cost = {
		[Enum.UnlearnCost.MysticExtract] = tokenCost or 0,
		[Enum.UnlearnCost.MarksOfAscension] = markCost or 0,
	}

	CostUtil:FinalazeCost(items, cost, finalCost, indexTable)

	return finalCost
end

function EnchantCollectionUtil:CalculateReforgeCost()
	local items = {
		[Enum.UnlearnCost.MarksOfAscension] = GetItemCount(ItemData.MARK_OF_ASCENSION),
	}

	local indexTable = {Enum.UnlearnCost.MarksOfAscension}
	local finalCost = {}

	local tokenCost = C_MysticEnchant.GetReforgeCost()
	local cost = { 
		[Enum.UnlearnCost.MarksOfAscension] = tokenCost or 0,
	}

	CostUtil:FinalazeCost(items, cost, finalCost, indexTable)

	return finalCost
end

function EnchantCollectionUtil:ShowDestroySlotDialogue(slot, spellID)
	slot = self:GetRealSlotID(slot)

	local Closure = function() if self:AttemptOperation("Destroy", "CanDestroy", slot) then PlaySound(SOUNDKIT.SPELL_PR_ARTIFACT_LIGHTSWRATH_CAST_05) end end

	EnchantCollectionUtil:HandleCostDialogue(string.format(ENCHANT_COLLECTION_DESTROY_SLOT, (LinkUtil:GetSpellLink(spellID) or "")), Closure, nil)
end

function EnchantCollectionUtil:ShowApplyDialogue(func)
	local isReforge, hasUncollectedChanges = self:IsCollectionReforge()
	if isReforge then
		local cost = self:CalculateCollectionReforgeCost()
		if hasUncollectedChanges then
			self:HandleCostDialogue(ENCHANT_COLLECTION_APPLY_COLLECTION_REFORGE_WARN, func, cost)
		else
			self:HandleCostDialogue(ENCHANT_COLLECTION_APPLY_COLLECTION_REFORGE, func, cost)
		end
		return
	elseif (self:HasStagedChanges()) then
		func()
		return
	end
end

function EnchantCollectionUtil:ShowDisenchantItemDialogue(itemID, GUIDLow)
	local Closure = function() self:AttemptOperation("DisenchantItem", "CanDisenchantItem", GUIDLow, MysticEnchantUtil.NeedsToPurchaseExtract()) end
	local item = Item:CreateFromID(itemID)
	local msg = string.format(ENCHANT_COLLECTION_DISENCHANT_ITEM, (item:GetLink() or ""))

	local REData = C_MysticEnchant.GetEnchantInfoByItem(itemID)
	EnchantCollectionUtil:HandleCostDialogue(msg, Closure, self:CalculateExtractCost(REData.SpellID))
end

function EnchantCollectionUtil:ShowDisenchantSlotDialogue(slot, spellID)
	slot = self:GetRealSlotID(slot)

	local Closure = function() self:AttemptOperation("DisenchantSlot", "CanDisenchantSlot", slot, MysticEnchantUtil.NeedsToPurchaseExtract()) end
	local msg = string.format(ENCHANT_COLLECTION_DISENCHANT_SLOT, (LinkUtil:GetSpellLink(spellID) or ""))

	EnchantCollectionUtil:HandleCostDialogue(msg, Closure, self:CalculateExtractCost(spellID))
end

function EnchantCollectionUtil:ShowCollectionReforgeItemDialogue(itemID, GUIDLow, spellID, func)
	local Closure = function() if self:AttemptOperation("CollectionReforgeItem", "CanCollectionReforgeItem", GUIDLow, spellID) then func() end end
	local item = Item:CreateFromID(itemID)
	local msg = string.format(ENCHANT_COLLECTION_SCROLL_COLLECTION_REFORGE_DIALOGUE, (LinkUtil:GetSpellLink(spellID) or ""), (item:GetLink() or ""))

	EnchantCollectionUtil:HandleCostDialogue(msg, Closure, self:GetCollectionReforgeItemCost(spellID))
end

-- TODO: Consider moving to CostUtil
function EnchantCollectionUtil:FormatCostIconOnly(cost)
	local msg = ""
	local canPay = CostUtil:CanPayThePrice(cost)
	local colorStr = canPay and "|cffFFFFFF" or "|cffFF0000"

	local indexCount = 1

    for index, amount in pairs(cost) do
    	local costStr = CostUtil:FormatCost(index, amount, true)

    	if (amount == 1) then
    		costStr = string.gsub(costStr, "^x1", "")
    	end

        msg = msg..colorStr..costStr.."|r"

        if (indexCount > 1) then
        	msg = msg.."\n"
        end

        indexCount = indexCount + 1
    end

    return msg
end

function EnchantCollectionUtil:HandleCostDialogue(msg, func, cost)
	StaticPopupDialogs["ASC_APPLY_EC_CONFIRM"].OnAccept = func

	local canPay, isFree = CostUtil:CanPayThePrice(cost)

	if not(isFree) then
		msg = msg..THIS_WOULD_REQUIRE

	    for index, amount in pairs(cost) do
	        msg = msg..CostUtil:FormatCost(index, amount).."\n"
	    end
	end

    StaticPopupDialogs["ASC_APPLY_EC_CONFIRM"].canPay = canPay
    StaticPopupDialogs["ASC_APPLY_EC_CONFIRM"].text = msg
	StaticPopup_Show("ASC_APPLY_EC_CONFIRM")
end

function EnchantCollectionUtil:GetSpecString(REData)
	local specString = nil

	if not REData or not REData.ClassRequirements then
		return ""
	end

	local existingClasses = {}
	
	for i, classRequirement in ipairs(REData.ClassRequirements) do
		local class = classRequirement.ClassType

		if class and not existingClasses[class] then
			local classFileName = CharacterAdvancementUtil.GetClassFileByDBC(class)
			if classFileName then
				local coloredStr = ClassInfoUtil.GetColoredClassName(classFileName)

				existingClasses[class] = true

				if coloredStr then
					specString = coloredStr .. (specString and ", " .. specString or "")
				end
			end
		end
	end

	return specString or ""
end

function EnchantCollectionUtil.IsClassAndSpecAppropriate(enchant)
	local missingAE, missingTE
	local investedAE, investedTE

	if enchant and enchant.ClassRequirements then
		for i, classRequirement in ipairs(enchant.ClassRequirements) do
			for _, tabType in ipairs(classRequirement.TabTypes) do
				investedAE = C_CharacterAdvancement.GetLearnedAE(classRequirement.ClassType, tabType.Tab)
				investedTE = C_CharacterAdvancement.GetLearnedTE(classRequirement.ClassType, tabType.Tab)

				if tabType.RequiredTE > 0 then
					if investedTE < tabType.RequiredTE then
						missingTE = true
					else
						return true
					end
				end

				if tabType.RequiredAE > 0 then
					if investedAE < tabType.RequiredAE then
						missingAE = true
					else
						return true
					end
				end
			end
		end
	end
	
	return not missingAE and not missingTE
end 
