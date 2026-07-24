function InGlue()
	return false
end

EXPANSION_MAX_LEVEL = {
    [0] = 60, -- Vanilla / Classic
    [1] = 70, -- TBC
    [2] = 80, -- WoTLK
}
-- returns the max level for the given expansion or accounts current expansion level
function GetMaxLevel(xpac)
	if xpac then 
		return EXPANSION_MAX_LEVEL[xpac] or 60
	end
	return GetRealmMaxLevel() or 60
end

MAX_LEVEL_ACHIEVEMENTS = {
	[60] = 11,
	[70] = 12,
	[80] = 13,
}
function HasMaxLevelOnRealm()
	local maxLevel = GetMaxLevel()
	local achievementID = MAX_LEVEL_ACHIEVEMENTS[maxLevel] or 11
	return select(4, GetAchievementInfo(achievementID)) == true
end

EXPANSION_ILVL_SOFT_CAP = {
	[0] = 96, -- Vanilla / Classic
	[1] = 174, -- TBC
	[2] = 277, -- WoTLK
}
-- returns the rough ilvl soft cap for the current expansion. Legendaries will exceed this such as atiesh.
function GetItemLevelSoftCap(xpac)
	xpac = xpac or GetExpansionLevel()
	return EXPANSION_ILVL_SOFT_CAP[xpac] or EXPANSION_ILVL_SOFT_CAP[0]
end

-- Strips item links to return the item id and the stripped link
function GetItemInfoFromHyperlink(link)
	if not link then
		return
	end
	local strippedItemLink, itemID = link:match("item:((%d+).-)");
	if itemID then
		return tonumber(itemID), strippedItemLink;
	end
end

-- Returns gold, silver, and copper from a money value
function GetGoldForMoney(money)
	local gold, silver, copper = 0, 0, 0

	gold = floor(abs(money / 1e4))
	silver = floor(abs(mod(money / 100, 100)))
	copper = floor(abs(mod(money, 100)))

	return gold, silver, copper
end

local QUALITY_MAP = {
	POOR = 0,
	GREY = 0,

	COMMON = 1,
	NORMAL = 1,
	WHITE = 1,

	UNCOMMON = 2,
	GREEN = 2,

	RARE = 3,
	BLUE = 3,

	EPIC = 4,
	PURPLE = 4,

	LEGENDARY = 5,
	ORANGE = 5,

	ARTIFACT = 6,
	VANITY = 6,

	HEIRLOOM = 7,
}
-- Converts a quality string to its numeric counterpart
function QualityStringToNumber(quality)
	if type(quality) == "number" then
		return quality
	end

	quality = strupper(quality)
	return QUALITY_MAP[quality]
end

-- Condense a tooltip to a reasonable length
function WordWrapLine(line, length)
	length = length or 46
	if line:len() <= length then return line end

	local count = 0
	local str = ""
	for word in line:gmatch("([^\32]*)") do
		if word:len() > 0 then
			if word:find("\n") or word:find("\r") then
				count = 0
			end

			if not word:find("|T") then
				if count >= length then
					count = 0
					str = str .."\n" .. word
				else
					if str ~= "" then
						str = str .. " " .. word
					else
						str = word
					end
				end
				count = count + word:len()
			else
				if str ~= "" then
					str = str .. " " .. word
				else
					str = word
				end
			end
		end
	end
	return str
end

-- Returns a spell link with the rank, i.e: [Regrowth (Rank 4)]
function GetSpellRankLink(spellId)
	if not spellId then return end
	
	local spellName, spellRank = GetSpellInfo(spellId)
	
	if not spellName then return end

	local str = "|Hspell:%d|h|cff71d5ff[%s]|r|h"
	
	local spellLine = spellName
	if spellRank and spellRank ~= "" then
		spellLine = spellLine .. " ("..spellRank..")"
	end
	
	return format(str, spellId, spellLine)
end

-- gets an item link
function GetItemLink(...)
	local _, link = GetItemInfo(...)
	return link
end

function GetInstantItemLink(itemID)
	local _, link = GetItemInfo(itemID)
	if link then
		return link
	end
	
	local quality = GetItemQuality(itemID)
	local name = GetItemName(itemID)
	if name then
		return ITEM_QUALITY_COLORS[quality or 1]:WrapText("|Hitem:"..itemID.."|h["..name.."]|h")
	end
end

-- Returns the currently viewed map expansion
function GetMapExpansion()
	local continent = GetCurrentMapContinent()
	if continent <= 2 then return 0 end
	if continent == 3 then return 1 end
	if continent == 4 then return 2 end
end

-- Gets Spell Charges using an action ID
function GetActionCharges(actionID)
	local actionType, id, _, globalID = GetActionInfo(actionID)
	if actionType ~= "spell" and actionType ~= "macro" then return end

	if actionType == "macro" then
		globalID = C_Spell:GetSpellID(GetMacroSpell(id))
	end
	
	if type(globalID) == "number" and globalID > 0 then
		return GetSpellCharges(globalID)
	end
end

function IsItemBloodforged(itemID) 
	local flavor = GetItemFlavorText(itemID)
	return flavor and flavor:find("Bloodforged", 1, true) ~= nil
end

function IsItemHeroic(itemID)
	local flavor = GetItemFlavorText(itemID)
	return flavor and flavor:find("Heroic", 1, true) ~= nil
end

function IsItemAscended(itemID)
	local flavor = GetItemFlavorText(itemID)
	return flavor and flavor:find("Ascended", 1, true) ~= nil
end

function IsItemMythic(itemID)
	local flavor = GetItemFlavorText(itemID)
	return flavor and flavor:find("Mythic", 1, true) ~= nil
end

function GetItemMythicLevel(itemID)
	local isMythic = IsItemMythic(itemID)
	if not isMythic then return 0 end
	local flavor = GetItemFlavorText(itemID)
	if flavor then
		local level = flavor:match("Mythic (.*)")
		level = level and tonumber(level)
		return level
	end
end

function GetInventoryItemWeaponSpeed(unit, slot)
	local itemID = GetInventoryItemID(unit, slot)
	if not itemID then return 0 end
	return GetItemWeaponSpeed(itemID) / 1000 or 0
end

hooksecurefunc("SuggestInvite", function(unit)
    if string.isNilOrEmpty(unit) then
        return
    end
	SendSystemMessage(format(MSG_SUGGESTED_INVITE, UnitName(unit) or unit))
end)

hooksecurefunc("RequestInvite", function(unit)
	local name = UnitName(unit) or unit
	SendSystemMessage(format(MSG_REQUESTED_INVITE, name))
	UIParent.RequestedInvites[name] = true
	Timer.After(60, function()
		UIParent.RequestedInvites[name] = nil
	end)
end)

local TemporaryFactionAuras
function GetUnitBattlefieldFaction(unit)
	if not unit then return end
	if not TemporaryFactionAuras then
		TemporaryFactionAuras = AuraUtil.MakeAuraGroup(86475, 86476)
	end
	local id = select(11, AuraUtil.HasBuff(unit, TemporaryFactionAuras, false, AuraUtil.Predicate.MatchesAuraGroup))
	if id == 86475 then
		return "Alliance", FACTION_ALLIANCE
	elseif id == 86476 then
		return "Horde", FACTION_HORDE
	end

	return UnitFactionGroup(unit)
end

function GetDifficultyInfo(difficultyID)
	return _G["GENERIC_DIFFICULTY"..difficultyID]
end

function GetClassID(class)
	if not class then return end
	return Enum.Class[class]
end

--
-- GetNumWatchedTokens is garbage
--
function GetNumWatchedCurrencies()
	for i = MAX_WATCHED_TOKENS, 1, -1 do
		if GetBackpackCurrencyInfo(i) then
			return i
		end
	end
	
	return 0
end

function GetUnitRealmNameKey(unit)
	return UnitName(unit or "player") .. "-" .. GetRealmName()
end


function UnitSpecAndIcon(unit)
	local _, class = UnitClass(unit)
	if IsCustomClass(unit) then
		-- CoA classes should look for their spec icon first
		if unit == "player" then -- only supports player atm
			local activeSpecID = C_CharacterAdvancement.GetActiveChrSpec()
			if activeSpecID and activeSpecID ~= 0 then
				local specInfo = ClassInfoUtil.GetSpecInfoByPassiveID(class, activeSpecID)
				if specInfo then
					return specInfo.Name, "Interface\\Icons\\" .. specInfo.SpecFilename
				end
			end
		end
	elseif IsHeroClass(unit) then
		local legendaryEnchantID = MysticEnchantUtil.GetLegendaryEnchantID(unit)
		if legendaryEnchantID then
			local name, _, icon = GetSpellInfo(legendaryEnchantID)
			if icon then
				return name, icon
			end
		end
	end

	return LOCALIZED_CLASS_NAMES_MALE[class], "Interface\\Icons\\classicon_" .. class:lower()
end

function UnitHealthPercent(unit)
	if UnitExists(unit) then
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
		if health and maxHealth and maxHealth > 0 then
			return math.ceil(100 * (health / maxHealth))
		end
		return 100
	end
	-- returns nil if no unit exists
end

function UnitMissingHealth(unit)
	if UnitExists(unit) then
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
		if health and maxHealth and maxHealth > 0 then
			return maxHealth - health
		end
		return 0
	end
	-- returns nil if no unit exists
end

function UnitPowerPercent(unit)
	if UnitExists(unit) then
		local power, maxPower = UnitPower(unit), UnitPowerMax(unit)
		if power and maxPower and maxPower > 0 then
			return math.ceil(100 * (power / maxPower))
		end
		return 0 -- assume no power if max power is also 0
	end
	-- returns nil if no unit exists
end

function UnitMissingPower(unit)
	if UnitExists(unit) then
		local power, maxPower = UnitPower(unit), UnitPowerMax(unit)
		if power and maxPower and maxPower > 0 then
			return maxPower - power
		end
		return 0
	end
	-- returns nil if no unit exists
end

function UnitGroupRolesAssignedKey(unit)
	local tank, healer, dps = UnitGroupRolesAssigned(unit)
	if tank then
		return "TANK"
	elseif healer then
		return "HEALER"
	elseif dps then
		return "DAMAGER"
	end
	
	return "NONE"
end

function Ambiguate(fullName, context)
	return fullName
end

function GetNormalizedRealmName()
	return Sub(GetRealmName(), "[-%s]", "")
end

function HasOverrideActionBar()
	return BonusActionBarFrame:IsShown()
end

function HasVehicleActionBar()
	return VehicleMenuBar:IsShown()
end

function IsInGroup()
	return GroupUtil.GetNumGroupMembers() > 1
end

function IsInRaid()
	return GetNumRaidMembers() > 0
end

function GetSpecialization()
	if IsCustomClass("player") then
		local _, class = UnitClass("player")
		local specs = C_ClassInfo.GetAllSpecs(class)
		for index, spec in ipairs(specs) do
			local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
			if C_CharacterAdvancement.IsKnownID(specInfo.PassiveID) then
				return specInfo.ID
			end
		end
	elseif IsDefaultClass("player") then
		local _, class = UnitClass("player")
		local bestSpec, highestTE = nil, 0
		for _, spec in ipairs(C_ClassInfo.GetAllSpecs(class)) do
			local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
			if specInfo then
				local dbcClass = CharacterAdvancementUtil.GetClassDBCByFile(class)
				local dbcSpec = CharacterAdvancementUtil.GetSpecDBCByFile(spec.Spec)
				local teInvestment = C_CharacterAdvancement.GetLearnedTE(dbcClass, dbcSpec)
				if teInvestment > highestTE then
					bestSpec, highestTE = specInfo.ID, teInvestment
				end
			end
		end
		
		return bestSpec or 0
	end
	
	return 0
end

function GetSpecializationInfoByID(specID)
	local specInfo = C_ClassInfo.GetSpecInfoByID(specID)
	if specInfo then
		--id, name, description, icon, role, classFile, className
		local role = "DAMAGER"
		if specInfo.Healer then
			role = "HEALER"
		elseif specInfo.Tank then
			role = "TANK"
		end
		return specInfo.ID, specInfo.Name, specInfo.Description, "Interface\\Icons\\"..specInfo.SpecFilename, role, specInfo.Class, LOCALIZED_CLASS_NAMES_MALE[specInfo.Class]
	end
end

function GetSpecializationInfo(specID)
	local specInfo = C_ClassInfo.GetSpecInfoByID(specID)
	if specInfo then
		--id, name, description, icon, role, primaryStat
		local role = "DAMAGER"
		if specInfo.Healer then
			role = "HEALER"
		elseif specInfo.Tank then
			role = "TANK"
		end
		
		local primaryStat = Enum.PrimaryStat[specInfo.PrimaryStats[1] or "Strength"]
		return specInfo.ID, specInfo.Name, specInfo.Description, "Interface\\Icons\\"..specInfo.SpecFilename, role, primaryStat
	end
end

function GetSpecializationRoleByID(specID)
	local specInfo = C_ClassInfo.GetSpecInfoByID(specID)
	if specInfo then
		--id, name, description, icon, role, primaryStat
		local role = "DAMAGER"
		if specInfo.Healer then
			role = "HEALER"
		elseif specInfo.Tank then
			role = "TANK"
		end

		return role
	end
end
GetSpecializationRole = GetSpecializationRoleByID

function GetInspectSpecialization(unit)
	-- unable to implement at this time
	return 0
end

function GetNumGroupMembers()
	return GroupUtil.GetNumGroupMembers()
end

function GetNumSubgroupMembers()
    return GroupUtil.GetNumPartyMembers()
end

function GetSpellBookItemInfo(index, bookType)
	local link = GetSpellLink(index, bookType)
	if not link then return end
	local spellID = tonumber(link:match("spell:(%d*)"))
	if spellID then
		return bookType, spellID
	end
end

function GetSpellBookItemName(index, bookType)
	local name, rank = GetSpellInfo(index, bookType)
	if name then
		local link = GetSpellLink(index, bookType)
		if not link then return end
		local spellID = tonumber(link:match("spell:(%d*)"))
		if spellID then
			return name, rank, spellID
		end
	end
end

function CombatLogGetCurrentEventInfo(...)
	if ( ... ) then
		-- 3.3.5 payload
		local Timestamp, SubEvent, SrcGUID, SrcName, SrcFlag, DstGUID, DstName, DstFlag = ...

		-- Invalid modern payloads
		local HideCaster = false
		local SrcRaidFlag = nil
		local DstRaidFlag = nil

		-- Return modern payload
		return Timestamp, SubEvent, HideCaster, SrcGUID, SrcName, SrcFlag, SrcRaidFlag, DstGUID, DstName, DstFlag, DstRaidFlag, select(9, ...)
	end
end

-- compatability
CA_IsSpellKnown = IsSpellIDKnown
