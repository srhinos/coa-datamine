StatsPanelMixin = CreateFromMixins(ScrollListMixin)

CR_DYNAMIC_STATS = {
	[Enum.StatQueryGroup.MeleeHit] = 0,
	[Enum.StatQueryGroup.RangedHit] = 0,
	[Enum.StatQueryGroup.SpellHit] = 0,
	[Enum.StatQueryGroup.Expertise] = 0,
	[Enum.StatQueryGroup.OffHandHit] = 0,
}

PAPERDOLL_CATEGORY_ORDERS = {}
RegisterForSave("PAPERDOLL_CATEGORY_ORDERS")

-- some functions need extra args aside from (statFrame[, unit])
-- otherwise directly reference the function if it only takes (statFrame[, unit])
PAPERDOLL_STATINFO = {
	-- General
	["ITEMLEVEL"] = PaperDollFrame_SetItemLevel,
	["PRIMARY_STAT"] = PaperDollFrame_SetPrimaryStat,
	["PRESTIGE_LEVEL"] = PaperDollFrame_SetPrestigeLevel,

	-- Base stats
	["STRENGTH"] = function(statFrame, unit) PaperDollFrame_SetStat(statFrame, 1, unit) end,
	["AGILITY"] = function(statFrame, unit) PaperDollFrame_SetStat(statFrame, 2, unit) end,
	["INTELLECT"] = function(statFrame, unit) PaperDollFrame_SetStat(statFrame, 4, unit) end,
	["SPIRIT"] = function(statFrame, unit) PaperDollFrame_SetStat(statFrame, 5, unit) end,
	["STAMINA"] = function(statFrame, unit) PaperDollFrame_SetStat(statFrame, 3, unit) end,
	["PVE_POWER"] = PaperDollFrame_SetPvEPower,
	["PVP_POWER"] = PaperDollFrame_SetPvPPower,

	-- Melee
	["MELEE_DAMAGE"] = PaperDollFrame_SetDamage,
	["MELEE_ATTACK_SPEED"] = PaperDollFrame_SetAttackSpeed,
	["ATTACK_POWER"] = PaperDollFrame_SetAttackPower,
	["MELEE_HIT_RATING"] = function(statFrame) PaperDollFrame_SetRating(statFrame, CR_HIT_MELEE) end,
	["ARMOR_PENETRATION"] = PaperDollFrame_SetArmorPenetration,
	["OFF_HAND_HIT_RATING"] = PaperDollFrame_SetMeleeOffHandHit,
	["MELEE_CRIT_CHANCE"] = PaperDollFrame_SetMeleeCritChance,
	["MELEE_EXPERTISE"] = PaperDollFrame_SetExpertise,
	
	-- Ranged
	["RANGED_DAMAGE"] = PaperDollFrame_SetRangedDamage,
	["RANGED_ATTACK_SPEED"] = PaperDollFrame_SetRangedAttackSpeed,
	["RANGED_ATTACK_POWER"] = PaperDollFrame_SetRangedAttackPower,
	["RANGED_HIT_RATING"] = function(statFrame) PaperDollFrame_SetRating(statFrame, CR_HIT_RANGED) end,
	["RANGED_CRIT_CHANCE"] = PaperDollFrame_SetRangedCritChance,
	
	-- Spells 
	["SPELL_DAMAGE"] = PaperDollFrame_SetSpellBonusDamage,
	["HEALING_POWER"] = PaperDollFrame_SetSpellBonusHealing,
	["SPELL_HIT_RATING"] = function(statFrame) PaperDollFrame_SetRating(statFrame, CR_HIT_SPELL) end,
	["SPELL_PENETRATION"] = PaperDollFrame_SetSpellPenetration,
	["SPELL_CRIT_RATING"] = PaperDollFrame_SetSpellCritChance,
	["SPELL_HASTE_RATING"] = PaperDollFrame_SetSpellHaste,
	["MANA_REGENERATION"] = PaperDollFrame_SetManaRegen,
	
	-- Defense
	["ARMOR"] = PaperDollFrame_SetArmor,
	["DEFENSE"] = PaperDollFrame_SetDefense,
	["DODGE"] = PaperDollFrame_SetDodge,
	["PARRY"] = PaperDollFrame_SetParry,
	["BLOCK"] = PaperDollFrame_SetBlock,
	["RESILIENCE"] = PaperDollFrame_SetResilience,
	
	-- Resistances
	["ARCANE_RESIST"] = function(statFrame, unit) PaperDollFrame_SetResistance(statFrame, 6, unit) end,
	["FIRE_RESIST"] = function(statFrame, unit) PaperDollFrame_SetResistance(statFrame, 2, unit) end,
	["NATURE_RESIST"] = function(statFrame, unit) PaperDollFrame_SetResistance(statFrame, 3, unit) end,
	["FROST_RESIST"] = function(statFrame, unit) PaperDollFrame_SetResistance(statFrame, 4, unit) end,
	["SHADOW_RESIST"] = function(statFrame, unit) PaperDollFrame_SetResistance(statFrame, 5, unit) end,
	
	-- manastorm
	["HIGHEST_SOLO_MANASTORM"] = PaperDollFrame_SetSoloManastorm,
	["HIGHEST_DUO_MANASTORM"] = PaperDollFrame_SetDuoManastorm,
	["HIGHEST_TRIO_MANASTORM"] = PaperDollFrame_SetTrioManastorm,
	["HIGHEST_GROUP_MANASTORM"] = PaperDollFrame_SetGroupManastorm,
}

local STAT_CATEGORIES = {
	{
		category = "CHARACTER_INFO",
		collapsed = false,
		stats = {
			{ key = "PRIMARY_STAT", classMask = Enum.ClassMask.HERO },
			{ key = "PVE_POWER", minLevel = GetMaxLevel() },
			{ key = "PVP_POWER", minLevel = GetMaxLevel() },
			"ITEMLEVEL",
			"PRESTIGE_LEVEL",
		}
	},
	{
		category = "PLAYERSTAT_DEFENSES",
		collapsed = false,
		stats = {
			"ARMOR",
			"DEFENSE",
			"DODGE",
			"PARRY",
			"BLOCK",
			"RESILIENCE",
		},
	},
	{
		category = "STAT_ATTRIBUTES_LABEL",
		collapsed = false,
		stats = {
			"STRENGTH",
			"AGILITY",
			"INTELLECT",
			"SPIRIT",
			"STAMINA",
		},
		priority = math.huge
	},
	{
		category = "PLAYERSTAT_MELEE_COMBAT",
		collapsed = false,
		stats = {
			"MELEE_DAMAGE",
			"MELEE_ATTACK_SPEED",
			"ATTACK_POWER",
			"MELEE_HIT_RATING",
			"OFF_HAND_HIT_RATING",
			"ARMOR_PENETRATION",
			"MELEE_CRIT_CHANCE",
			"MELEE_EXPERTISE",
		},
		priority = function(unit)
			local base, pos, neg = UnitAttackPower(unit)
			return base + pos + neg
		end,
	},
	{
		category = "PLAYERSTAT_RANGED_COMBAT",
		collapsed = false,
		stats = {
			"RANGED_DAMAGE",
			"RANGED_ATTACK_SPEED",
			"RANGED_ATTACK_POWER",
			"RANGED_HIT_RATING",
			"ARMOR_PENETRATION",
			"RANGED_CRIT_CHANCE",
		},
		priority = function(unit)
			local base, pos, neg = UnitRangedAttackPower(unit)
			return base + pos + neg
		end,
	},
	{
		category = "PLAYERSTAT_SPELL_COMBAT",
		collapsed = false,
		stats = {
			"SPELL_DAMAGE",
			"HEALING_POWER",
			"SPELL_HIT_RATING",
			"SPELL_PENETRATION",
			"SPELL_HASTE_RATING",
			"SPELL_CRIT_RATING",
			"MANA_REGENERATION",
		},
		priority = function(unit)
			local spellDamage = PaperDollFrame_GetBonusSpellDamage(unit)
			if unit == "pet" then
				return spellDamage
			end
			
			return math.max(GetSpellBonusHealing(), spellDamage)
		end,
	},
	{
		category = "PLAYERSTAT_RESISTANCES",
		collapsed = false,
		stats = {
			"ARCANE_RESIST",
			"FIRE_RESIST",
			"NATURE_RESIST",
			"FROST_RESIST",
			"SHADOW_RESIST",
		},
		priority = -math.huge
	},
}

local PET_STAT_CATEGORIES = {
	{
		category = "STAT_ATTRIBUTES_LABEL",
		collapsed = false,
		stats = {
			"STRENGTH",
			"AGILITY",
			"INTELLECT",
			"SPIRIT",
			"STAMINA",
		}
	},
	{
		category = "STAT_ENHANCEMENTS",
		collapsed = false,
		stats = {
			"ATTACK_POWER",
			"MELEE_DAMAGE",
			"SPELL_DAMAGE",
			"ARMOR",
		}
	},
	{
		category = "PLAYERSTAT_RESISTANCES",
		collapsed = false,
		stats = {
			"ARCANE_RESIST",
			"FIRE_RESIST",
			"NATURE_RESIST",
			"FROST_RESIST",
			"SHADOW_RESIST",
		}
	},
}

local TARGET_STAT_CATEGORIES = {
	{
		category = "CHARACTER_INFO",
		collapsed = false,
		stats = {
			{ key = "PRIMARY_STAT", classMask = Enum.ClassMask.HERO },
			{ key = "PVE_POWER", minLevel = GetMaxLevel() },
			{ key = "PVP_POWER", minLevel = GetMaxLevel() },
			"ITEMLEVEL",
		}
	},
	{
		category = "THE_MANASTORM",
		collapsed = false,
		stats = {
			"HIGHEST_SOLO_MANASTORM",
			"HIGHEST_DUO_MANASTORM",
			"HIGHEST_TRIO_MANASTORM",
			"HIGHEST_GROUP_MANASTORM",
		}
	}
}

local function ClearStatButton(stat)
	stat.tooltip = nil
	stat.tooltip2 = nil
	stat.minTooltipWidth = nil
	-- for melee damage stats this has to be here
	stat.unit = nil
	stat.onEnterFunc = nil
	stat.offhandDamage = nil
	stat.offhandAttackSpeed = nil
	stat.offhandDps = nil
	stat.damage = nil
	stat.attackSpeed = nil
	stat.dps = nil
end

local DEFAULT_CATEGORY_ORDER = {
	"CHARACTER_INFO",
	"THE_MANASTORM",
	"STAT_ATTRIBUTES_LABEL",
	"PLAYERSTAT_MELEE_COMBAT",
	"PLAYERSTAT_RANGED_COMBAT",
	"PLAYERSTAT_SPELL_COMBAT",
	"PLAYERSTAT_DEFENSES",
	"PLAYERSTAT_RESISTANCES",
}

function StatsPanelMixin:OnLoad()
	if ScrollListMixin.OnLoad then
		ScrollListMixin.OnLoad(self)
	end
	self.unit = "player"
	
	self.sortedStats = {}
	self:SetTemplate("StatsPanelStatButtonTemplate")
	self:SetGetNumResultsFunction(function() return #self.sortedStats end)
	self:GetSelectedHighlight():SetTexture()
	self:RegisterEvent("VARIABLES_LOADED")
end

function StatsPanelMixin:OnShow()
	self.Background:SetAtlas(GetCharacterFrameSidePanelBackgroundAtlas(self:GetUnit()))
	C_Cache:QueryAllStats()

	self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	self:RegisterEvent("UNIT_LEVEL")
	self:RegisterEvent("UNIT_RESISTANCES")
	self:RegisterEvent("UNIT_STATS")
	self:RegisterEvent("UNIT_DAMAGE")
	self:RegisterEvent("UNIT_RANGEDDAMAGE")
	self:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
	self:RegisterEvent("UNIT_ATTACK_SPEED")
	self:RegisterEvent("UNIT_ATTACK_POWER")
	self:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:RegisterEvent("UNIT_ATTACK")
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:RegisterEvent("COMBAT_RATING_UPDATE")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("MYSTIC_ENCHANT_SLOT_UPDATE")

	C_Hook:Register(self, "PROCESSED_STATISTIC_QUERY_PAYLOAD", function(queryType, value)
		self:OnEvent("PROCESSED_STATISTIC_QUERY_PAYLOAD", queryType, value)
	end)

	C_Hook:RegisterBucket(self, "UNIT_AURA", 0.1, function(events)
		local unit
		for _, event in ipairs(events) do
			unit = event[1]
			if unit == "player" or unit == "pet" then
				self:OnEvent("UNIT_AURA", unit)
				return
			end
		end
	end)

	C_Hook:RegisterBucket(self, "SPELLS_CHANGED", 0.1, function()
		self:OnEvent("SPELLS_CHANGED")
	end)

	C_Hook:RegisterBucket(self, "ASCENSION_HIDDEN_SPELL_LEARNED", 0.1, function()
		self:OnEvent("SPELLS_CHANGED")
	end)

	C_Hook:RegisterBucket(self, "ASCENSION_HIDDEN_SPELL_UNLEARNED", 0.1, function()
		self:OnEvent("SPELLS_CHANGED")
	end)

	self:ScheduleUpdate()
end

function StatsPanelMixin:OnHide()
	C_Hook:Unregister(self)
	self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
	self:UnregisterEvent("UNIT_LEVEL")
	self:UnregisterEvent("UNIT_RESISTANCES")
	self:UnregisterEvent("UNIT_STATS")
	self:UnregisterEvent("UNIT_DAMAGE")
	self:UnregisterEvent("UNIT_RANGEDDAMAGE")
	self:UnregisterEvent("PLAYER_DAMAGE_DONE_MODS")
	self:UnregisterEvent("UNIT_ATTACK_SPEED")
	self:UnregisterEvent("UNIT_ATTACK_POWER")
	self:UnregisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:UnregisterEvent("UNIT_ATTACK")
	self:UnregisterEvent("SKILL_LINES_CHANGED")
	self:UnregisterEvent("COMBAT_RATING_UPDATE")
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:UnregisterEvent("MYSTIC_ENCHANT_SLOT_UPDATE")
end

function StatsPanelMixin:OnEvent(event, ...)
	if event == "VARIABLES_LOADED" then
		local orderKey = GetUnitRealmNameKey("player")
		local myCategoryOrder = PAPERDOLL_CATEGORY_ORDERS[orderKey]

		if not myCategoryOrder then
			myCategoryOrder = table.Copy(DEFAULT_CATEGORY_ORDER)
			PAPERDOLL_CATEGORY_ORDERS[orderKey] = myCategoryOrder
		else
			local defaultCategories = table.invert(DEFAULT_CATEGORY_ORDER)
			-- Remove any categories that no longer exist
			for i = #myCategoryOrder, 1, -1 do
				if not defaultCategories[myCategoryOrder[i]] then
					tremove(myCategoryOrder, i)
				end
				defaultCategories[myCategoryOrder[i]] = nil
			end
			
			-- Add any new categories
			for category, index in pairs(defaultCategories) do
				tinsert(myCategoryOrder, index, category)
			end
		end
		
		self.CategoryOrder = myCategoryOrder
		self:UpdateStatOrder()
		return
	end
	local unit = ...
	if (event == "UNIT_AURA" and unit == "player") or
			event == "PLAYER_EQUIPMENT_CHANGED" or
			event == "SPELLS_CHANGED" or
			event == "MYSTIC_ENCHANT_SLOT_UPDATE" then
		C_Cache:QueryAllStats(true)
	elseif event == "PROCESSED_STATISTIC_QUERY_PAYLOAD" then
		local queryType, value = ...
		CR_DYNAMIC_STATS[queryType] = value
	end
	if self:IsVisible() then
		self:ScheduleUpdate()
	end
end

function StatsPanelMixin:ScheduleUpdate()
	-- defer the update until the next frame so all changes are run at once
	self:SetScript("OnUpdate", self.UpdateStats)
end

function StatsPanelMixin:SetUnit(unit)
	self.unit = unit
end

function StatsPanelMixin:GetUnit()
	return self.unit
end

function StatsPanelMixin:IsUnit(unit)
	return unit and self.unit and UnitIsUnit(self.unit, unit)
end

function StatsPanelMixin:GetAppropriateStatCategory()
	if self:IsUnit("pet") then
		return PET_STAT_CATEGORIES
	elseif self:IsUnit("player") then
		return STAT_CATEGORIES
	else
		return TARGET_STAT_CATEGORIES
	end
end

function StatsPanelMixin:SetCategoryCollapsed(categoryName)
	local categories = self:GetAppropriateStatCategory()
	for _, category in pairs(categories) do
		if category.category == categoryName then
			category.collapsed = not category.collapsed
			self:ScheduleUpdate()
			return
		end
	end
end

function StatsPanelMixin:UpdateStatOrder()
	local order = table.invert(self.CategoryOrder)
	table.sort(STAT_CATEGORIES, function(left, right)
		return order[left.category] < order[right.category]
	end)
	if self:IsVisible() then
		self:ScheduleUpdate()
	end
end

function StatsPanelMixin:MoveCategoryUp(categoryName)
	local order = table.invert(self.CategoryOrder)
	local index = order[categoryName]
	if index == 1 then
		return
	end
	local prevCategoryName = self.CategoryOrder[index - 1]
	self.CategoryOrder[index - 1] = categoryName
	self.CategoryOrder[index] = prevCategoryName
	self:UpdateStatOrder()
end

function StatsPanelMixin:MoveCategoryDown(categoryName)
	local order = table.invert(self.CategoryOrder)
	local index = order[categoryName]
	if index == #self.CategoryOrder then
		return
	end
	local nextCategoryName = self.CategoryOrder[index + 1]
	self.CategoryOrder[index + 1] = categoryName
	self.CategoryOrder[index] = nextCategoryName
	self:UpdateStatOrder()
end

function StatsPanelMixin:UpdateStats()
	self:SetScript("OnUpdate", nil)
	wipe(self.sortedStats)
	local statCategories = self:GetAppropriateStatCategory()
	local classMask = UnitClassMask(self:GetUnit())

	for _, categoryInfo in ipairs(statCategories) do
		tinsert(self.sortedStats, { categoryInfo.category, categoryInfo.collapsed })
		if not categoryInfo.collapsed then
			for _, stat in ipairs(categoryInfo.stats) do
				-- if this stat is a table, it has some unit filtering
				if type(stat) == "table" then
					local passed = true
					if stat.classMask then
						passed = passed and bit.contains(stat.classMask, classMask)
					end

					if stat.minLevel then
						passed = passed and UnitLevel(self:GetUnit()) >= stat.minLevel
					end

					if passed then
						tinsert(self.sortedStats, PAPERDOLL_STATINFO[stat.key])
					end
				else
					tinsert(self.sortedStats, PAPERDOLL_STATINFO[stat])
				end
			end
		end
	end

	self:RefreshScrollFrame()
end

function StatsPanelMixin:GetStatInfoByIndex(index)
	local statInfo = self.sortedStats[index]
	local isHeader = type(statInfo) == "table"
	if isHeader then
		return statInfo[1], self:GetUnit(), isHeader, statInfo[2]
	end
	return statInfo, self:GetUnit(), isHeader
end

--
-- Stat Mixin
--
StatsPanelStatMixin = CreateFromMixins(CollapsibleButtonMixin, ScrollListItemBaseMixin)

function StatsPanelStatMixin:Init()
	ScrollListItemBaseMixin.Init(self)
	self.Background:SetAtlas("UI-Character-Info-Line-Bounce", Const.TextureKit.IgnoreAtlasSize)
end

function StatsPanelStatMixin:Update()
	ClearStatButton(self)
	self.statInfo, self.unit, self.isHeader, self.isCollapsed = self:GetScrollList():GetStatInfoByIndex(self.index)
	if self.isHeader then
		self.StatText:Hide()
		self.Label:Hide()
		self.Background:Hide()

		self.ExpandOrCollapseIcon:Show()
		self.Text:Show()
		self.Left:Show()
		self.Right:Show()
		self.Middle:Show()

		if self.unit == "player" then
			self.MoveUpButton:Show()
			self.MoveDownButton:Show()
		else
			self.MoveUpButton:Hide()
			self.MoveDownButton:Hide()
		end

		self.Text:SetText(_G[self.statInfo])
		self:SetIsCollapsed(self.isCollapsed)
	else
		self.Text:Hide()
		self.ExpandOrCollapseIcon:Hide()
		self.Left:Hide()
		self.Right:Hide()
		self.Middle:Hide()
		self.MoveUpButton:Hide()
		self.MoveDownButton:Hide()

		self.StatText:Show()
		self.Label:Show()
		self.Background:Show()
		self.Background:SetAlpha(self.index % 2 == 0 and 0.2 or 0)

		self.statInfo(self, self.unit)
	end
end

function StatsPanelStatMixin:OnSelected()
	if self.isHeader then
		PlaySound(SOUNDKIT.MINI_MAP_ZOOM_70)
		self:GetScrollList():SetCategoryCollapsed(self.statInfo)
		AscensionCharacterStatsPanel:ScheduleUpdate()
	end
end

function StatsPanelStatMixin:MoveCategoryUp()
	if not self.isHeader then return end
	self:GetScrollList():MoveCategoryUp(self.statInfo)
end

function StatsPanelStatMixin:MoveCategoryDown()
	if not self.isHeader then return end
	self:GetScrollList():MoveCategoryDown(self.statInfo)
end

function StatsPanelStatMixin:OnEnter()
	if self.onEnterFunc then
		-- see CharacterDamageFrame_OnEnter / PaperDollFrame_SetDamage
		-- mess i dont wanna change right now
		return self:onEnterFunc()
	end

	if not self.tooltip then return end

	GameTooltip_GenericTooltip(self, "ANCHOR_RIGHT")
	
	if self.minTooltipWidth then
		GameTooltip:SetMinimumWidth(self.minTooltipWidth, true)
		GameTooltip:Show()
	end
end

function StatsPanelStatMixin:OnLeave()
	GameTooltip:Hide()
end
