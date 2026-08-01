local ReturnFalse = function() return false end
local EmptyFunc = function() end

DiscordFeaturesEnabled = DiscordFeaturesEnabled or ReturnFalse
DiscordOpenGuildInvite = DiscordOpenGuildInvite or EmptyFunc

-- Suggest UI Reload on RetstartGx because a ton of custom textures just turn into white boxes if they dont
_RestartGx = _RestartGx or RestartGx
function RestartGx()
	StaticPopup_Show("RESTART_GX_SUGGEST_RELOAD")
	_RestartGx()
end

-- Overwrite SetGuildRosterShowOffline to send addon message for toggling offline player data or not.
-- Fixes lag in massive guilds
_SetGuildRosterShowOffline = _SetGuildRosterShowOffline or SetGuildRosterShowOffline
function SetGuildRosterShowOffline(show)
	local message

	if show then
		message = "ACTION_ENABLE_OFFLINE_ROSTER_UPDATE"
	else
		message = "ACTION_DISABLE_OFFLINE_ROSTER_UPDATE"
	end

	SendAddonMessage("ASC_GUILD", message, "WHISPER", UnitName("player"))
	_SetGuildRosterShowOffline(show)
end

-- Overwrite GetSavedInstanceInfo to show the correct name for mythic dungeons / custom raid difficulties
_GetSavedInstanceInfo = _GetSavedInstanceInfo or GetSavedInstanceInfo
function GetSavedInstanceInfo(index)
	local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName = _GetSavedInstanceInfo(index)
	if (maxPlayers > 5) then
		difficultyName = _G["RAID_DIFFICULTY" .. instanceDifficulty] or difficultyName
	else
		difficultyName = _G["DUNGEON_DIFFICULTY" .. instanceDifficulty] or difficultyName
	end

	return instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName
end

-- Overwrite GetItemStats to return PVE and PVP Power

_GetItemStats = _GetItemStats or GetItemStats
function GetItemStats(itemLink, statTable)
	local itemID = GetItemInfoFromHyperlink(itemLink)
	statTable = statTable or {}
	_GetItemStats(itemLink, statTable)

	local itemInfo = GetItemInfoInstant(itemID)
	if itemInfo then
		statTable["PVE_POWER"] =  itemInfo.pvePower or 0
		statTable["PVP_POWER"] = itemInfo.pvpPower or 0
	end

	return statTable
end

-- Overwrite GetGuildBankTabInfo to always allow interaction with Personal Banks
local function IsPersonalBank()
	-- pBank_BankType is addon defined. Must call with securecall or will taint entire guildbank ui
	return GuildBankFrame and GuildBankFrame.IsPersonalBank
end

local function IsRealmBank()
	return GuildBankFrame and GuildBankFrame.IsRealmBank
end

_GetGuildBankTabInfo = _GetGuildBankTabInfo or GetGuildBankTabInfo
function GetGuildBankTabInfo(id)
	local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = _GetGuildBankTabInfo(id)

	if securecall(IsPersonalBank) or securecall(IsRealmBank) then
		isViewable = 1
		canDeposit = 1
		numWithdrawals = -1
		remainingWithdrawals = -1
	end

	return name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals
end

--
-- Overwrite Unit Class to return class id and class mask
--
_UnitClass = _UnitClass or UnitClass
function UnitClass(target)
	local className, classFileName = _UnitClass(target)
	return className, classFileName, Enum.Class[classFileName], Enum.ClassMask[classFileName]
end

_UnitClassBase = _UnitClassBase or UnitClassBase
function UnitClassBase(target)
	local className, classFileName = _UnitClassBase(target)
	return className, classFileName, Enum.Class[classFileName], Enum.ClassMask[classFileName]
end

function UnitClassID(target)
	local _, _, id = UnitClassBase(target)
	return id
end

function UnitClassMask(target)
	local _, _, _, mask = UnitClassBase(target)
	return mask
end
_UnitRace = _UnitRace or UnitRace
function UnitRace(target)
	local race, raceFileName = _UnitRace(target)
	return race, raceFileName, Enum.Race[raceFileName]
end

function GetClassInfo(classID)
	if not classID then
		return nil
	end
	
	local class
	if Enum.Class[classID] then
		class = classID
		classID = Enum.Class[class]
	else
		class = Enum.ClassFile[classID]
	end

	if not class then
		return nil
	end

	return LOCALIZED_CLASS_NAMES_MALE[class], class, classID, Enum.ClassMask[class]
end

--
-- Overwrite GetFriendInfo 
--
_GetFriendInfo = _GetFriendInfo or GetFriendInfo
function GetFriendInfo(id)
	local name, level, class, area, connected, status, note = _GetFriendInfo(id)
	if name then
		local metaName = C_Social:GetFriendAddedAs(name)
		if metaName and metaName:len() > 0 then
			area = area .. " |cffFFD100Added as: (" .. metaName .. ")|r"
		end
	end
	return name, level, class, area, connected, status, note
end

_AddFriend = _AddFriend or AddFriend
function AddFriend(player)
	assert(type(player) == "string")
	_AddFriend(player)
	player = player:firstUpper()
	C_Social:SetFriendAddedAs(player, player)
end

_AddOrRemoveFriend = _AddOrRemoveFriend or AddOrRemoveFriend
function AddOrRemoveFriend(player)
	if not player or player == "" then
		player = UnitIsPlayer("target") and UnitName("target")
	end

	if not player or player == "" then return end

	_AddOrRemoveFriend(player)

	player = player:firstUpper()
	C_Social:SetFriendAddedAs(player, player)
end

_CalculateAuctionDeposit = _CalculateAuctionDeposit or CalculateAuctionDeposit
function CalculateAuctionDeposit(duration, count, startPrice, buyoutPrice)
	-- duration is 1 (12 hr), 2 (24hr) 3 (48hr)
	-- count is stack size * stack count
	local deposit = _CalculateAuctionDeposit(duration, count)

	if not deposit or deposit <= 0 or not StartPrice or not BuyoutPrice then
		return deposit
	end

	-- vanity items have no vendor price, manually overwrite deposit to match core
	--2% 12h
	--4% 24hr
	--8%  48h
	--20g max (1s min)
	local name, _, _, quality = GetAuctionSellItemInfo()
	local maxValue, depositMulti
	if name and quality == Enum.ItemQuality.Vanity then
		maxValue = C_Config.GetIntConfig("CONFIG_MAX_AUCTION_DEPOSIT_VANITY") or 200000
		depositMulti = C_Config.GetRateConfig("RATE_AUCTION_DEPOSIT_VANITY") or 0.0833
		startPrice = startPrice or MoneyInputFrame_GetCopper(StartPrice)
		buyoutPrice = buyoutPrice or MoneyInputFrame_GetCopper(BuyoutPrice)
		deposit = math.max(startPrice, buyoutPrice) * depositMulti
		deposit = MClamp(deposit, 100, maxValue)
	else
		depositMulti = C_Config.GetRateConfig("RATE_AUCTION_DEPOSIT")
		deposit = math.ceil(deposit * depositMulti)
	end
	
	return math.ceil(deposit)
end

_GetLFDChoiceLockedState = _GetLFDChoiceLockedState or GetLFDChoiceLockedState
function GetLFDChoiceLockedState(tbl)
	if not tbl then tbl = {} end
	_GetLFDChoiceLockedState(tbl)

	for dungeonID, events in pairs(C_LFG.RequiresGameEvent) do
		if type(events) == "table" then
			if not GameEventUtil.IsAnyEventActive(unpack(events)) then
				tbl[dungeonID] = 2
			end
		else
			if not GameEventUtil.IsAnyEventActive(events) then
				tbl[dungeonID] = 2
			end
		end
	end
	
	return tbl
end

_UnitDamage = _UnitDamage or UnitDamage
local LUNAR_COMBATANT_SPELL_ID = 805828
local LUNAR_COMBATANT_BONUS_WEAPON_DAMAGE_PER_SPELLPOWER = 1/9

function UnitDamage(unit)
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = _UnitDamage(unit);
	if unit == "player" and select(2, UnitClass(unit)) == "HERO" then
		if minDamage == 0 and maxDamage == 0 then
			return minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent
		end
		local spellPower = PaperDollFrame_GetBonusSpellDamage()
		local bonusDamage = BONUS_WEAPON_DAMAGE_PER_SPELLPOWER * spellPower

		local _, offHandSpeed = UnitAttackSpeed(unit)
		if offHandSpeed then
			offHandSpeed = GetInventoryItemWeaponSpeed("player", INVSLOT_OFFHAND)
			minOffHandDamage = minOffHandDamage + (bonusDamage * offHandSpeed)
			maxOffHandDamage = maxOffHandDamage + (bonusDamage * offHandSpeed)
		end

		local mainHandSpeed = GetInventoryItemWeaponSpeed("player", INVSLOT_MAINHAND)
		minDamage = minDamage + (bonusDamage * mainHandSpeed)
		maxDamage = maxDamage + (bonusDamage * mainHandSpeed)
	end

	if unit == "player" and select(2, UnitClass(unit)) == "STARCALLER" and C_Aura and C_Aura.UnitHasAura(unit, LUNAR_COMBATANT_SPELL_ID) then
		if minDamage == 0 and maxDamage == 0 then
			return minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent
		end
		local spellPower = PaperDollFrame_GetBonusSpellDamage()
		local bonusDamage = LUNAR_COMBATANT_BONUS_WEAPON_DAMAGE_PER_SPELLPOWER * spellPower

		local _, offHandSpeed = UnitAttackSpeed(unit)
		if offHandSpeed then
			offHandSpeed = GetInventoryItemWeaponSpeed("player", INVSLOT_OFFHAND)
			minOffHandDamage = minOffHandDamage + (bonusDamage * offHandSpeed)
			maxOffHandDamage = maxOffHandDamage + (bonusDamage * offHandSpeed)
		end

		local mainHandSpeed = GetInventoryItemWeaponSpeed("player", INVSLOT_MAINHAND)
		minDamage = minDamage + (bonusDamage * mainHandSpeed)
		maxDamage = maxDamage + (bonusDamage * mainHandSpeed)
	end
	
	return minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent
end

_UnitRangedDamage = _UnitRangedDamage or UnitRangedDamage
function UnitRangedDamage(unit)
	local rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent = _UnitRangedDamage(unit)
	if unit == "player" and select(2, UnitClass(unit)) == "HERO" then
		if minDamage == 0 and maxDamage == 0 then
			return rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent
		end
		local spellPower = PaperDollFrame_GetBonusSpellDamage()
		local bonusDamage = BONUS_WEAPON_DAMAGE_PER_SPELLPOWER * spellPower * GetInventoryItemWeaponSpeed("player", INVSLOT_RANGED)
		
		minDamage = minDamage + bonusDamage
		maxDamage = maxDamage + bonusDamage
	end

	if unit == "player" and select(2, UnitClass(unit)) == "STARCALLER" and C_Aura and C_Aura.UnitHasAura(unit, LUNAR_COMBATANT_SPELL_ID) then
		if minDamage == 0 and maxDamage == 0 then
			return rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent
		end
		local spellPower = PaperDollFrame_GetBonusSpellDamage()
		local bonusDamage = LUNAR_COMBATANT_BONUS_WEAPON_DAMAGE_PER_SPELLPOWER * spellPower * GetInventoryItemWeaponSpeed("player", INVSLOT_RANGED)

		minDamage = minDamage + bonusDamage
		maxDamage = maxDamage + bonusDamage
	end
	
	return rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent
end

_GetNumTitles = _GetNumTitles or GetNumTitles
function GetNumTitles()
	-- GetNumTiltes returns the number of dbc rows + 1, which is always 1 higher than it should be.
	-- IsTitleKnown(GetNumTitles()) would always return 0, so this never was an issue
	-- but if 191+ titles are in the dbc, it would return 1 because IsTitleKnown always returns true for 192+ (if numTitles >= the value as well)
	return _GetNumTitles() - 1
end

-- theres an achievement for reaching level 10 so this should be fine, function seems to randomly break on its own.
function HasCompletedAnyAchievement()
	return UnitLevel("player") >= 10
end

_UnitCastingInfo = _UnitCastingInfo or UnitCastingInfo
function UnitCastingInfo(unit)
	local name, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, noInterrupt = _UnitCastingInfo(unit)
	return name, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, noInterrupt, UnitCastingSpellID(unit)
end

_UnitChannelInfo = _UnitChannelInfo or UnitChannelInfo
function UnitChannelInfo(unit)
	local name, rank, displayName, icon, startTime, endTime, isTradeSkill, noInterrupt = _UnitChannelInfo(unit)
	return name, rank, displayName, icon, startTime, endTime, isTradeSkill, noInterrupt, UnitCastingSpellID(unit)
end

--
-- GetInventoryItemQuality doesn't actually work for other units
-- so just do it manually
--
function GetInventoryItemQuality(unit, slot)
	local itemID = GetInventoryItemTrueID(unit, slot)
	if not itemID then
		return
	end

	return select(3,  GetItemInfo(itemID)) or GetItemQuality(itemID)
end

--
-- GetInventoryItemID in many cases will return the transmog item id instead.
--
function GetInventoryItemTrueID(unit, slot)
	local itemLink = GetInventoryItemLink(unit, slot)
	return itemLink and GetItemInfoFromHyperlink(itemLink)
end

function GetInventorySlotInfoByID(slotID)
	if not slotID then return end
	return GetInventorySlotInfo(INVSLOT_TO_SLOTNAME[slotID])
end

--
-- GetInboxInvoiceInfo doesn't return quantity in 3.3.5
--
_GetInboxInvoiceInfo = _GetInboxInvoiceInfo or GetInboxInvoiceInfo
function GetInboxInvoiceInfo(index)
	local invoiceType, itemName, playerName, bid, buyout, deposit, consignment, moneyDelay, etaHour, etaMin = _GetInboxInvoiceInfo(index)
	return invoiceType, itemName, playerName, bid, buyout, deposit, consignment, moneyDelay, etaHour, etaMin, GetInboxInvoiceQuantity(index)
end

--
-- C_CharacterAdvancement Overwrites
--
local C_CharacterAdvancement_GetGlobalTEInvestment = C_CharacterAdvancement.GetGlobalTEInvestment
function C_CharacterAdvancement.GetGlobalTEInvestment(...)
	return C_CVar.GetBool("previewCharacterAdvancementChanges") and C_CharacterAdvancement.GetPendingGlobalTEInvestment(...) or C_CharacterAdvancement_GetGlobalTEInvestment(...)
end

local C_CharacterAdvancement_GetTabTEInvestment = C_CharacterAdvancement.GetTabTEInvestment
function C_CharacterAdvancement.GetTabTEInvestment(...)
	return C_CVar.GetBool("previewCharacterAdvancementChanges") and C_CharacterAdvancement.GetPendingTabTEInvestment(...) or C_CharacterAdvancement_GetTabTEInvestment(...)
end

local C_CharacterAdvancement_GetClassPointInvestment = C_CharacterAdvancement.GetClassPointInvestment
function C_CharacterAdvancement.GetClassPointInvestment(...)
	return C_CVar.GetBool("previewCharacterAdvancementChanges") and C_CharacterAdvancement.GetPendingClassPointInvestment(...) or C_CharacterAdvancement_GetClassPointInvestment(...)
end

local C_CharacterAdvancement_GetGlobalAEInvestment = C_CharacterAdvancement.GetGlobalAEInvestment
function C_CharacterAdvancement.GetGlobalAEInvestment(...)
	return C_CVar.GetBool("previewCharacterAdvancementChanges") and C_CharacterAdvancement.GetPendingGlobalAEInvestment(...) or C_CharacterAdvancement_GetGlobalAEInvestment(...)
end

local C_CharacterAdvancement_CanLearnID = C_CharacterAdvancement.CanLearnID
function C_CharacterAdvancement.CanLearnID(...)
	return C_CVar.GetBool("previewCharacterAdvancementChanges") and C_CharacterAdvancement.CanAddByEntryID(..., 1) or C_CharacterAdvancement_CanLearnID(...)
end

local C_CharacterAdvancement_CanUnlearnID = C_CharacterAdvancement.CanUnlearnID
function C_CharacterAdvancement.CanUnlearnID(...)
	return C_CVar.GetBool("previewCharacterAdvancementChanges") and C_CharacterAdvancement.CanRemoveByEntryID(..., 1) or C_CharacterAdvancement_CanUnlearnID(...)
end

local C_CharacterAdvancement_GetQualityInfo = C_CharacterAdvancement.GetQualityInfo
function C_CharacterAdvancement.GetQualityInfo(spellID)
	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then -- exception for wildcard talents. Rank means quality for talents
		-- TODO: Not a perfect solution, but will work for now.
		-- rework it so we always know what rank the spell passes in 
		local currentRank, maxRank = C_CharacterAdvancement.GetTalentRankBySpellID(spellID)

		if currentRank and (maxRank > 1) then
			return currentRank, 0
		end
	end

	local quality, qualityCount = C_CharacterAdvancement_GetQualityInfo(spellID)
	quality = quality and Enum.SpellQuality[quality] or quality
	return quality, qualityCount
end

local C_CharacterAdvancement_GetQualityCount = C_CharacterAdvancement.GetQualityCount
function C_CharacterAdvancement.GetQualityCount(quality)
	return C_CharacterAdvancement_GetQualityCount(Enum.QualityToCAQuality[quality])
end

local C_CharacterAdvancement_GetQualityLimit = C_CharacterAdvancement.GetQualityLimit
function C_CharacterAdvancement.GetQualityLimit(quality)
	return C_CharacterAdvancement_GetQualityLimit(Enum.QualityToCAQuality[quality])
end

local _GetInstanceInfo = GetInstanceInfo
function GetInstanceInfo()
	local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic = _GetInstanceInfo()
	local mapID = GetActiveMapID()
	return name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, mapID
end 

_NotifyInspect = NotifyInspect
function NotifyInspect(unit)
	if AscensionInspectFrame and AscensionInspectFrame:IsShown() then
		return
	end
	_NotifyInspect(unit)
end

_GetAuctionItemInfo = GetAuctionItemInfo
function GetAuctionItemInfo(...)
	local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner, saleStatus, itemId, hasAllInfo = _GetAuctionItemInfo(...)

	if level then
		level = GetAuctionItemRequiredLevel(...) or level
	end
	
	return name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner, saleStatus, itemId, hasAllInfo
end

--
-- GetItemCount hackfix for Character Advancement. Requires proper fix later
--
_GetItemCount = _GetItemCount or GetItemCount

function GetItemCount(...)
	local itemID = ...

	if itemID == ItemData.ABILITY_ESSENCE then
		return C_CharacterAdvancement.GetRemainingAE() or 0
	elseif itemID == ItemData.TALENT_ESSENCE then
		return C_CharacterAdvancement.GetRemainingTE() or 0
	end

	return _GetItemCount(...)
end

--
-- replace GetGameTime with GetServerTime
--
local _GetGameTime = GetGameTime
function GetGameTime()
	local t = date("*t", GetServerTime())
	return t.hour or 0, t.min or 0
end

--
-- replace load addon to load the correct addon
local _LoadAddOn = LoadAddOn
function LoadAddOn(name)
	if name == "Ascension_CharacterAdvancement" then
		if IsCustomClass() then
			return _LoadAddOn("Ascension_CoATalents")
		end
		
		if IsDefaultClass() then
			return _LoadAddOn("Ascension_CharacterAdvancement")
		end

		local useLegacy = C_Config.GetBoolConfig("CONFIG_LEGACY_CHARACTER_ADVANCEMENT_ENABLED")
		if useLegacy == nil or useLegacy == true or CA_FORCE_LEGACY then
			return _LoadAddOn("Ascension_CharacterAdvancementSeason9")
		else
			return _LoadAddOn("Ascension_CharacterAdvancement")
		end
	end
	
	return _LoadAddOn(name)
end

--
-- GetArmorPenetration
function GetArmorPenetration()
	local ratingBonus = GetCombatRatingBonus(CR_ARMOR_PENETRATION)
	local getAuraBonus = C_Aura and C_Aura.GetArmorPenetrationModifier
	local auraBonus = getAuraBonus and getAuraBonus() or 0
	return math.max(0, math.min(100, ratingBonus + auraBonus))
end

--
-- Strip leading '!' chars from spell book tab names (used server-side for sort ordering)
--
_GetSpellTabInfo = _GetSpellTabInfo or GetSpellTabInfo
function GetSpellTabInfo(...)
	local name, texture, offset, numSpells, isGuild, offSpecID = _GetSpellTabInfo(...)
	if type(name) == "string" then
		name = name:gsub("^!+", "")
	end
	return name, texture, offset, numSpells, isGuild, offSpecID
end
