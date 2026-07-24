WildCardUtil = CreateFrame("FRAME")
WildCardUtil.CHARACTER_ADVANCEMENT_LEVEL_SORT_IDS = {}

--
-- List of possible internal IDs per level
--
function WildCardUtil.CheckCAData(data)
	if bit.contains(data.Flags, Enum.CharacterAdvancementFlag.HiddenClientside) then
		return false
	end

	if (data.Type ~= "Talent") and (data.Type ~= "Ability") then
		return false
	end

	return true
end

--[[function WildCardUtil.InitFakeIDTable(sourceTable)
	for class, classData in pairs(sourceTable) do
		for tab, tabData in pairs(classData) do
			for internalID, data in pairs(tabData) do
				if WildCardUtil.CheckCAData(data) then
					local spellID = CharacterAdvancementUtil.GetSpellByID(internalID)
					for level = data.RequiredLevel, GetMaxLevel() do
						WildCardUtil.CHARACTER_ADVANCEMENT_LEVEL_SORT_IDS[level] = WildCardUtil.CHARACTER_ADVANCEMENT_LEVEL_SORT_IDS[level] or {}
						if not C_CharacterAdvancement.IsMastery(spellID) then
							table.insert(WildCardUtil.CHARACTER_ADVANCEMENT_LEVEL_SORT_IDS[level], internalID)
						end
					end
				end
			end
		end
	end
end

function WildCardUtil.InitFakeIDTables()
	WildCardUtil.InitFakeIDTable(CHARACTER_ADVANCEMENT_SPELLS)
	WildCardUtil.InitFakeIDTable(CHARACTER_ADVANCEMENT_TALENTS)
end

function WildCardUtil.GetFakeIDTable(level)
	local currTime = GetTime()

	local tbl = {}
	local sourceTable = WildCardUtil.CHARACTER_ADVANCEMENT_LEVEL_SORT_IDS[level]

	for i = 1, math.min(#sourceTable, 100) do
		local internalID = sourceTable[math.random(1, #sourceTable)]

		if not(C_CharacterAdvancement.IsKnownID(internalID)) then
			table.insert(tbl, internalID)
		end
	end

	return tbl
end]]--

function WildCardUtil.IsDiceVisible()
	if not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		return false
	end

	if not(IsAddOnLoaded("Ascension_WildCard")) then
		return false
	end

	if not(WildCardDice) then
		return false
	end

	if WildCardDice:IsVisible() then
		return true
	end
end

function WildCardUtil.GetVisibleDice()
	if WildCardUtil.IsDiceVisible() then
		return WildCardDice
	end
end

function WildCardUtil.IsRapidRolling()
	return WildCardDice and WildCardDice.isRapidRolling
end

-- Display-only: the server is the source of truth for whether a reroll is
-- blocked. Limits only constrain rerolls while the matching essence (AE for
-- abilities, TE for talents) is unspent; a cap of -1 means uncapped.
function WildCardUtil.GetAvailableRerolls(entryType, specID)
	specID = specID or SpecializationUtil.GetActiveSpecialization()
	if not specID then
		return 0, 0, false
	end

	local isTalent = entryType == "Talent" or entryType == "TalentAbility"
	local hasUnspentEssence = GetItemCount(isTalent and ItemData.TALENT_ESSENCE or ItemData.ABILITY_ESSENCE) > 0
	local limits = C_WildcardRewards.GetScrollOfFortuneLimits and C_WildcardRewards.GetScrollOfFortuneLimits(specID)
	local isLimited = hasUnspentEssence and limits ~= nil

	local typedToken = isTalent and TokenUtil.GetScrollOfFortuneTalentsForSpec(specID) or TokenUtil.GetScrollOfFortuneAbilitiesForSpec(specID)
	local pools = {
		{ count = TokenUtil.GetTokenCount(typedToken), limit = limits and (isTalent and limits.talent or limits.ability) },
		{ count = TokenUtil.GetTokenCount(TokenUtil.GetScrollOfFortuneForSpec(specID)), limit = limits and limits.generic },
	}

	local available, total = 0, 0
	for _, pool in ipairs(pools) do
		total = total + pool.count
		if isLimited and pool.limit and pool.limit.cap ~= -1 then
			available = available + math.min(pool.count, math.max(0, pool.limit.cap - pool.limit.used))
		else
			available = available + pool.count
		end
	end

	return available, total, isLimited
end

--
-- Loading stuff
--
function WildCardUtil.LoadWildCardUI()
	if not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", WildCardUtil.FilterLearnMessages)
		if IsAddOnLoaded("Ascension_WildCard") then
			WildCard:CheckForRolls()
		end
		return
	end

	WildCard_LoadUI()
end

function WildCardUtil.CanShowRollDice()
	if not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		return false
	end

	if not C_Wildcard then
		return false
	end

	if C_Wildcard.CanShowStartingChoice and C_Wildcard.CanShowStartingChoice() then
		return true
	end

	return C_Wildcard.CanRollAbilities and C_Wildcard.CanRollAbilities()
end

function WildCardUtil.ShowRollDiceFromSlashCommand()
	if not WildCardUtil.CanShowRollDice() then
		return false
	end

	local shouldShowStartingChoice = C_Wildcard.CanShowStartingChoice and C_Wildcard.CanShowStartingChoice()

	WildCard_LoadUI()

	if not IsAddOnLoaded("Ascension_WildCard") then
		return false
	end

	if shouldShowStartingChoice and WildCardDice and WildCardDice.ShowStartingChoicePanel then
		WildCardDice.startingChoiceKept = false
		if WildCardDice:ShowStartingChoicePanel("slash-command") then
			return true
		end
	end

	if WildCard then
		return WildCard:CheckForRolls()
	end

	return false
end

local learnSpellMessage = ERR_LEARN_SPELL_S:gsub("%%s", "(.+)")
local learnAbilityMessage = ERR_LEARN_ABILITY_S:gsub("%%s", "(.+)")
-- filter learn messages since wild card shows what rank is learned
function WildCardUtil.FilterLearnMessages(chatFrame, event, message)
	if message:match(learnSpellMessage) or message:match(learnAbilityMessage) then
		return true
	end
	
	return false
end
--
-- Events
--
C_Hook:Register(WildCardUtil, "ASCENSION_CUSTOM_GAME_MODE_CHANGED")
function WildCardUtil:ASCENSION_CUSTOM_GAME_MODE_CHANGED()
    WildCardUtil.LoadWildCardUI()
end

-- WILDCARD_ROLL_READY is fired by the client DLL when the player transitions
-- to being eligible to roll (initial login sync, post-level-up, post-roll,
-- etc.). It is the single authoritative trigger for loading the addon and
-- revealing the dice; the previous PLAYER_ENTERING_WORLD-driven load raced
-- the server's state sync and left the dice hidden until /reload.
local rollReadyListener = CreateFrame("Frame")
rollReadyListener:RegisterEvent("WILDCARD_ROLL_READY")
rollReadyListener:SetScript("OnEvent", function()
	WildCard_LoadUI()
end)
