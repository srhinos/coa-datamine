SkillCardUtil = CreateFrame("FRAME")

SkillCardUtil.events = {
	"CLAIM_SKILL_CARD_RESULT",
	"PENDING_SKILL_CARD_ADDED",
	"PENDING_SKILL_CARD_REMOVED",
	"SET_SKILL_CARD_RESULT",
	"SKILL_CARD_COLLECTION_ITEM_USED",
	"SKILL_CARD_AUTO_REVEALED",
}

SkillCardUtil.cardTypes = {
	[ItemData.ABILITY_SEALED_CARD_PACK] = Enum.SkillCardPurchaseCardTypes.DEFAULT_PACK,
	[ItemData.TALENT_SEALED_CARD_PACK] = Enum.SkillCardPurchaseCardTypes.DEFAULT_TALENT_PACK,
	[ItemData.GOLDEN_ABILITY_SEALED_CARD_PACK] = Enum.SkillCardPurchaseCardTypes.DEFAULT_GOLDEN_PACK,
	[ItemData.GOLDEN_TALENT_SEALED_CARD_PACK] = Enum.SkillCardPurchaseCardTypes.DEFAULT_GOLDEN_TALENT_PACK,
}

function SkillCardUtil.RegisterEvents()
	for _, event in pairs(SkillCardUtil.events) do
		SkillCardUtil:HookEvent(event)
	end
end

function SkillCardUtil.HandleError(errorStr)
	if not(errorStr) or (errorStr == "") or (type(errorStr) ~= "string") then
		return
	end

	errorStr = _G[errorStr] or errorStr

	SendSystemMessage("|cffFF0000"..errorStr.."|r")
	UIErrorsFrame:AddMessage(errorStr, 1, 0, 0)
end

local function SkillCardUtil_SafeCall(func, ...)
	if type(func) ~= "function" then
		return nil
	end

	local ok, result = pcall(func, ...)
	if ok then
		return result
	end

	return nil
end

local function SkillCardUtil_FormatBool(value)
	if value == nil then
		return "unknown"
	end

	return tostring(value)
end

local function SkillCardUtil_GetKnownSpellEntryCount()
	local entries = SkillCardUtil_SafeCall(C_CharacterAdvancement and C_CharacterAdvancement.GetKnownSpellEntries)
	return entries and #entries or nil
end

local function SkillCardUtil_GetResetUnaffectedKnownStarterAbilities()
	local entries = SkillCardUtil_SafeCall(C_CharacterAdvancement and C_CharacterAdvancement.GetKnownSpellEntries)
	if not entries then
		return nil
	end

	local resetUnaffectedStarterAbilities = {
		[6622] = "Burrow Bolt",
		[7099] = "Suffuse",
		[7409] = "Shooting Star",
		[7608] = "Abyssal Ward",
		[7722] = "Green Salve",
		[33979] = "Solar Prayer",
		[34402] = "Testament of Fortitude",
	}
	local found = {}
	for _, entry in ipairs(entries) do
		local entryID = entry and entry.ID
		if entryID and resetUnaffectedStarterAbilities[entryID] then
			table.insert(found, entryID .. ":" .. resetUnaffectedStarterAbilities[entryID])
		end
	end

	if #found == 0 then
		return "none seen client-side"
	end

	return table.concat(found, ", ")
end

function SkillCardUtil.DebugWildcardStartingPhaseComplete(result)
	if not C_Realm or not C_Realm.IsDevelopment or not C_Realm.IsDevelopment() then
		return
	end
	if type(dprint) ~= "function" then
		return
	end

	local request = SkillCardUtil.lastSetSkillCardRequest or {}
	local activeSpec = SkillCardUtil_SafeCall(C_CharacterAdvancement and C_CharacterAdvancement.GetActiveSpecID)
	local learnedSpellEntries = SkillCardUtil_GetKnownSpellEntryCount()
	local canRoll = SkillCardUtil_SafeCall(C_Wildcard and C_Wildcard.CanRollAbilities)
	local canShowStartingChoice = SkillCardUtil_SafeCall(C_Wildcard and C_Wildcard.CanShowStartingChoice)
	local willRollStarting = SkillCardUtil_SafeCall(C_Wildcard and C_Wildcard.WillRollStartingAbilities)
	local willRollFirstNonStarting = SkillCardUtil_SafeCall(C_Wildcard and C_Wildcard.WillRollFirstNonStartingAbility)
	local resetUnaffected = SkillCardUtil_GetResetUnaffectedKnownStarterAbilities()

	dprint("[SkillCards] " .. result .. " received.")
	dprint("[SkillCards] Last slot request: type=" .. tostring(request.cardType) .. " index=" .. tostring(request.index) .. " cardID=" .. tostring(request.cardID) .. " removing=" .. SkillCardUtil_FormatBool(request.removing) .. " age=" .. tostring(request.time and (GetTime() - request.time) or "unknown"))
	dprint("[SkillCards] Client state: activeSpec=" .. tostring(activeSpec) .. " knownSpellEntries=" .. tostring(learnedSpellEntries) .. " canRoll=" .. SkillCardUtil_FormatBool(canRoll) .. " canShowStartingChoice=" .. SkillCardUtil_FormatBool(canShowStartingChoice) .. " willRollStarting=" .. SkillCardUtil_FormatBool(willRollStarting) .. " willRollFirstNonStarting=" .. SkillCardUtil_FormatBool(willRollFirstNonStarting))
	dprint("[SkillCards] Reset-unaffected starter abilities known client-side: " .. tostring(resetUnaffected))
	dprint("[SkillCards] Server blocked because its learned Ability/TalentAbility count is past the starter boundary. Expected boundary: slot default/talent cards at 4 starters; block ability and talent cards after the 5th spell is learned.")
	dprint("[SkillCards] Likely causes: server already processed the 5th roll before this slot request; restored/deleted character carried old advancement rows; reset-unaffected starter ability survived a reset; locked/persisted starting entries make the server count differ from the UI; client has stale CA/WildCard state.")
	dprint("[SkillCards] Check server warning log category wildcard.skillcard for authoritative learnedAbilities/startCount/type/index/entry on this rejection.")
end

function SkillCardUtil.HandleEvent(event, argsTable)
	if (SkillCardsFrame and SkillCardsFrame:IsVisible()) then
		return
	end

	ShowSkillCards()

	--[[if (SkillCardsFrame) then
		print("Fire "..event.." in SkillCardsFrame")
		SkillCardsFrame[event](SkillCardsFrame, unpack(argsTable))
	else
		Timer.After(0.5, function() C_Hook:SendEvent(event, unpack(argsTable)) end)
		print("Delay "..event)
	end]]--
end

function SkillCardUtil.IsCardTypeGolden(cardType)
	if (cardType) then
		return (cardType == Enum.SkillCardType.SkillGolden) or (cardType == Enum.SkillCardType.StarterGolden) or (cardType == Enum.SkillCardType.LuckyGolden) or (cardType == Enum.SkillCardType.TalentGolden)
	end
end

function SkillCardUtil.IsCardTypeTalent(cardType)
	if (cardType) then
		return (cardType == Enum.SkillCardType.TalentNormal) or (cardType == Enum.SkillCardType.TalentGolden)
	end
end

function SkillCardUtil.IsStarterCardData(cardData)
	if not cardData then
		return false
	end

	if cardData.IsStarterCard ~= nil then
		return cardData.IsStarterCard
	end

	if not cardData.SpellID then
		return false
	end

	local entry = C_CharacterAdvancement.GetEntryBySpellID(cardData.SpellID)
	return entry and entry.RequiredLevel and entry.RequiredLevel <= 1
end

function SkillCardUtil.GetNumSkillCards(cardType)
	return C_SkillCardCollection.GetNumSkillCards(cardType)
end

function SkillCardUtil.SetSkillCardFilter(cardType, searchString, filters)
	C_SkillCardCollection.SetSkillCardFilter(cardType, searchString or "", filters)
end

function SkillCardUtil.GetSkillCardAtIndex(cardType, index)
	return C_SkillCardCollection.GetSkillCardAtIndex(cardType, index)
end

function SkillCardUtil.GetMaxCards(cardType, index)
	return C_SkillCard.GetMaxCardCount(cardType)
end

function SkillCardUtil.GetCardAtIndex(cardType, index)
	return C_SkillCard.GetCardAtIndex(cardType, index)
end

function SkillCardUtil.GetCardInfoAtIndex(cardType, index)
	return C_SkillCard.GetSkillCardInfoAtIndex(cardType, index)
end

function SkillCardUtil.HasAnyCardCollected(cardType)
	return C_SkillCardCollection.HasAnySkillCardsCollected(cardType)
end

function SkillCardUtil.IsCardAtIndexActive(cardType, index)
	return C_SkillCard.IsCardAtIndexActive(cardType, index)
end

function SkillCardUtil.SetCardAtIndex(cardType, index, cardID)
	SkillCardUtil.lastSetSkillCardRequest = {
		cardType = cardType,
		index = index,
		cardID = cardID,
		removing = false,
		time = GetTime(),
	}
	C_SkillCard.SetCardAtIndex(cardType, index, cardID)
end

function SkillCardUtil.RemoveCardAtIndex(cardType, index)
	SkillCardUtil.lastSetSkillCardRequest = {
		cardType = cardType,
		index = index,
		cardID = 0,
		removing = true,
		time = GetTime(),
	}
	C_SkillCard.RemoveCardAtIndex(cardType, index)
end

function SkillCardUtil.ClaimSkillCard(UUID)
	if type(UUID) == "string" then
		dprint("C_SkillCardCollection.ClaimPendingSkillCard "..UUID)
		C_SkillCardCollection.ClaimPendingSkillCard({UUID})
	elseif type(UUID) == "table" then
		dprint("C_SkillCardCollection.ClaimPendingSkillCard TOTAL: "..(#UUID))
		C_SkillCardCollection.ClaimPendingSkillCard(UUID)
	end
end

function SkillCardUtil.GetNumPendingCards()
	return C_SkillCardCollection.GetNumPendingSkillCards()
end

function SkillCardUtil.GetPendingSkillCardAtIndex(index)
	return C_SkillCardCollection.GetPendingSkillCardAtIndex(index)
end

function SkillCardUtil.GetBonusSealedCardPacksProgress()
	return C_SkillCardCollection:GetBonusSealedCardPacksProgress()*100
end

function SkillCardUtil.GetSkillCardInfo(cardID, rank)
	--[[struct: 
	{
		Expansion,
		CollectedRank,
		IsCollected,
		Class,
		CardID,
		Type,
		ItemID,
		CollectedProgress,
		Quality,
		QualityCost,
		SpellID,
		Rank
	}
	]]--
	return C_SkillCard.GetSkillCardInfo(cardID, rank)
end

function SkillCardUtil.LoadSkillCardsUtil()
	SkillCardUtil.RegisterEvents()

	if not(C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)) and not(C_GameMode:IsGameModeActive(Enum.GameMode.Draft)) then
		return
	end

	SkillCards_LoadUI()

	if SkillCardUtil.OnGameModeChangeHandle then
		SkillCardUtil.OnGameModeChangeHandle:Unregister()
		SkillCardUtil.OnGameModeChangeHandle = nil
	end
end

function SkillCardUtil.GetCollectedProgress(cardID)
	local progress = C_SkillCardCollection.GetProgress(cardID)

	-- if progress == 1 don't display progress bar
	return (progress or 1)*100
end

function SkillCardUtil.DefineCardType(itemID)
	return SkillCardUtil.cardTypes[itemID] or nil
end

SkillCardUtil.OnGameModeChangeHandle = C_GameMode:RegisterCallbackWithHandle("OnGameModeChanged",  SkillCardUtil.LoadSkillCardsUtil)

function SkillCardUtil:PENDING_SKILL_CARD_ADDED(...)
	SkillCardUtil.HandleEvent("PENDING_SKILL_CARD_ADDED", {...})
end

function SkillCardUtil:CLAIM_SKILL_CARD_RESULT(result)
	if string.find(result, "_OK$") then
		SkillCardUtil.HandleEvent("CLAIM_SKILL_CARD_RESULT")
	else
		SkillCardUtil.HandleError(result)
	end
end

function SkillCardUtil:PENDING_SKILL_CARD_REMOVED(...)
	SkillCardUtil.HandleEvent("PENDING_SKILL_CARD_REMOVED", {...})
end

function SkillCardUtil:SET_SKILL_CARD_RESULT(result)
	if string.find(result, "_OK$") then
		return
	end

	if result == "SET_SKILL_CARD_WILDCARD_STARTING_PHASE_COMPLETE" then
		SkillCardUtil.DebugWildcardStartingPhaseComplete(result)
	end

	SkillCardUtil.HandleError(result)
end

function SkillCardUtil:SKILL_CARD_COLLECTION_ITEM_USED()
	SkillCardUtil.HandleEvent("SKILL_CARD_COLLECTION_ITEM_USED")

	if SkillCardsFrame then
		SkillCardsFrame:SetTab(Enum.SkillCardTabs.BoostersTab)
	end
end

function SkillCardUtil:SKILL_CARD_AUTO_REVEALED()
	SkillCardUtil.HandleEvent("SKILL_CARD_AUTO_REVEALED")

	if SkillCardsFrame then
		SkillCardsFrame:SetTab(Enum.SkillCardTabs.BoostersTab)
	end
end
