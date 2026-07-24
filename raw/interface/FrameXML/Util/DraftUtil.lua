DraftUtil = {}

function DraftUtil.IsDraftActive()
	return C_GameMode:IsGameModeActive(Enum.GameMode.Draft)
end

function DraftUtil.IsBuildDraftActive()
	return C_GameMode:IsGameModeActive(Enum.GameMode.BuildDraft)
end

function DraftUtil.IsInCardSwapSacrifice()
	local pickCount = GetHandOfFateSacrificePickCount()
	return pickCount and pickCount == 1
end

function DraftUtil.IsInCardSwap()
	local pickCount = GetHandOfFateSacrificePickCount()
	return pickCount and pickCount == 1
end

function DraftUtil.HasSacrificePicks()
	return HasHandOfFateSacrificePick() and GetHandOfFateSacrificePickSpellAtIndex(0) ~= 0
end

function DraftUtil.HasHandOfFatePicks()
	return HasHandOfFatePick() and GetHandOfFatePickSpellAtIndex(0) ~= 0
end

function DraftUtil.HasDraftPicks()
	return HasDraftModePick() and GetDraftModePickSpellAtIndex(0) ~= 0
end

function DraftUtil.HasAnyPicks()
	return DraftUtil.HasSacrificePicks() or DraftUtil.HasHandOfFatePicks() or DraftUtil.HasDraftPicks()
end 

function DraftUtil.GetNumPicks()
	if DraftUtil.HasSacrificePicks() then
		return GetHandOfFateSacrificePickCount()

	elseif DraftUtil.HasHandOfFatePicks() then
		return GetHandOfFatePickCount()

	elseif DraftUtil.HasDraftPicks() then
		return GetDraftModePickCount()
	end

	return 0
end

function DraftUtil.GetPickSignature()
	if DraftUtil.HasSacrificePicks() then
		local count = GetHandOfFateSacrificePickCount()
		local ids = {}
		for i = 1, count do
			ids[i] = GetHandOfFateSacrificePickSpellAtIndex(i - 1)
		end
		return "sacrifice:" .. count .. ":" .. table.concat(ids, ",")
	elseif DraftUtil.HasHandOfFatePicks() then
		local count = GetHandOfFatePickCount()
		local ids = {}
		for i = 1, count do
			ids[i] = GetHandOfFatePickSpellAtIndex(i - 1)
		end
		return "hand:" .. count .. ":" .. table.concat(ids, ",")
	elseif DraftUtil.HasDraftPicks() then
		local count = GetDraftModePickCount()
		local ids = {}
		for i = 1, count do
			ids[i] = GetDraftModePickSpellAtIndex(i - 1)
		end
		return "draft:" .. count .. ":" .. table.concat(ids, ",")
	end
end

function DraftUtil.IsIndexSkillCard(index)
	if DraftUtil.HasHandOfFatePicks() then
		return IsSkillCardPick(index-1)
	else
		return IsSkillCardDraft(index-1)
	end
end

function DraftUtil.IsIndexLuckySkillCard(index)
	if DraftUtil.HasHandOfFatePicks() then
		return IsLuckySkillCardPick(index-1)
	else
		return IsLuckySkillCardDraft(index-1)
	end
end

function DraftUtil.GetSacrificePick(index)
	return GetHandOfFateSacrificePickSpellAtIndex(index-1)
end

function DraftUtil.GetHandOfFatePick(index)
	return GetHandOfFatePickSpellAtIndex(index-1)
end

function DraftUtil.GetDraftPick(index)
	return GetDraftModePickSpellAtIndex(index-1)
end

function DraftUtil.IsCardSwapSacrifice()
	local count = GetHandOfFateSacrificePickCount()
	return count and count == 1 and IsCardSwapSacrifice()
end

function DraftUtil.IsDraftGrantedByMastery()
	local pick = GetDraftModePickSpellAtIndex(0)
	return pick and CharacterAdvancementUtil.GetGrantingMasteryByID(pick)
end

function DraftUtil.GetConfirmLearnThreshold()
	if C_GameMode:IsGameModeActive(Enum.GameMode.Felforged) then
		return 20
	else
		return 9
	end
end

function DraftUtil.GetHandOfFateChoiceSpellID()
	local internalID = GetSelectedHandOfFateSpell()
	if internalID then
		return CharacterAdvancementUtil.GetSpellByID(internalID)
	end
end

function DraftUtil.IsSkillCardIDGold(internalID)
	local isCarded, skillCardType, active = C_SkillCard.IsCardedID(internalID)
	if not isCarded then
		return false
	end
	-- Check if the skill card type is golden (contains "GOLDEN" in the type name)
	return skillCardType and (skillCardType == Enum.SkillCardType.SkillGolden or
	                          skillCardType == Enum.SkillCardType.StarterGolden or
	                          skillCardType == Enum.SkillCardType.LuckyGolden or
	                          skillCardType == Enum.SkillCardType.TalentGolden)
end
C_Hook:Register(DraftUtil, "PLAYER_ENTERING_WORLD")
C_GameMode:RegisterCallback("OnGameModeChanged", function()
	local events = {}
	C_Hook:Unregister(DraftUtil)
	
	local draftEnabled = C_GameMode:IsGameModeActive(Enum.GameMode.Draft)
	if draftEnabled then
		events["ASCENSION_DRAFT_STATE_UPDATED"] = true
		events["ASCENSION_DRAFTMODE_DRAFT_PICK_CHANGED"] = true
		events["ASCENSION_DRAFTMODE_HAND_OF_FATE_CHANGED"] = true
		events["ASCENSION_DRAFTMODE_HAND_OF_FATE_SACRIFICE_CHANGED"] = true
		events["ASCENSION_RANDOMMODE_SKILLCARD_DEACTIVATED"] = true
		events["ASCENSION_RANDOMMODE_GOLDEN_SKILLCARD_DEACTIVATED"] = true
		events["PLAYER_REGEN_DISABLED"] = true
		events["CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED"] = true
	end

	if C_GameMode:IsGameModeActive(Enum.GameMode.BuildDraft) then
		events["ASCENSION_KNOWN_ENTRY_UPDATE"] = true
		--events["PLAYER_LEVEL_UP"] = true
	end
	
	for event in pairs(events) do
		C_Hook:Register(DraftUtil, event)
	end

	if draftEnabled then
		DraftUtil.CheckForPicks()
	end
end)

function DraftUtil.CheckForPicks()
	local signature = DraftUtil.GetPickSignature()
	local changed = signature ~= DraftUtil.LastPickSignature
	if changed then
		DraftUtil.LastPickSignature = signature
		if signature and IsAddOnLoaded("Ascension_Draft") then
			Draft:ResetRevealedCards()
		end
	end

	if DraftUtil.HasAnyPicks() then
		Draft_LoadUI()
		if changed or not Draft:IsDraftShown() then
			Draft:CheckForPicks()
		end
	elseif IsAddOnLoaded("Ascension_Draft") then
		Draft:InvalidateAllCards()
	end
end

function DraftUtil.ToggleDraftUI()
	Draft_LoadUI()
	Draft:ToggleVisible()
end

--
-- Draft Events
--
function DraftUtil:ASCENSION_DRAFTMODE_DRAFT_PICK_CHANGED()
	DraftUtil.CheckForPicks()
end

function DraftUtil:ASCENSION_DRAFT_STATE_UPDATED()
	DraftUtil.CheckForPicks()
end

function DraftUtil:ASCENSION_DRAFTMODE_HAND_OF_FATE_CHANGED()
	DraftUtil.CheckForPicks()
end 

function DraftUtil:ASCENSION_DRAFTMODE_HAND_OF_FATE_SACRIFICE_CHANGED()
	DraftUtil.CheckForPicks()
end

function DraftUtil:ASCENSION_RANDOMMODE_SKILLCARD_DEACTIVATED()
	DraftUtil.CheckForPicks()
end

function DraftUtil:ASCENSION_RANDOMMODE_GOLDEN_SKILLCARD_DEACTIVATED()
	DraftUtil.CheckForPicks()
end

function DraftUtil:PLAYER_ENTERING_WORLD()
	DraftUtil.CheckForPicks()
end

function DraftUtil:PLAYER_REGEN_DISABLED()
	if IsAddOnLoaded("Ascension_Draft") then
		Draft:HideCards()
	end
end

function DraftUtil:ASCENSION_KNOWN_ENTRY_UPDATED()
	DraftUtil.CheckForPicks()
end

--
-- Build Draft Events
--
function DraftUtil:ASCENSION_KNOWN_ENTRY_UPDATE(internalID, rank)
	if not C_CVar.GetBool("buildDraftShowSpellCards") then return end
	local spellID = CharacterAdvancementUtil.GetSpellByID(internalID)
	if C_CharacterAdvancement.IsMastery(spellID) then return end
	
	local activeBuild = BuildCreatorUtil.GetActiveBuildID()
	if not activeBuild then return end
	BuildCreatorUtil.ContinueOnLoad(activeBuild, function(build)
		if not build then return end
		local spellID = CharacterAdvancementUtil.GetSpellByID(internalID)
		if not spellID then return end
		local buildSpell = C_BuildCreator.GetSpell(build.ID, spellID)
		if bit.contains(buildSpell.Flags, Enum.BuildSpellFlags.NotifyOnLearn) then
			Draft_LoadUI()
			Draft:ShowLearnedSpell(internalID, rank)
		end
	end)
end

--[[function DraftUtil:PLAYER_LEVEL_UP(level)
	if not C_CVar.GetBool("buildDraftShowSpellCards") then return end
	if EnchantCollection and EnchantCollection:IsVisible() then return end

	local activeBuild = BuildCreatorUtil.GetActiveBuildID()
	if not activeBuild then return end
	BuildCreatorUtil.ContinueOnLoad(activeBuild, function(build)
		if not build then return end
		for _, buildEnchant in ipairs(build.RandomEnchants) do
			if buildEnchant.Level == level then
				Draft_LoadUI()
				Draft:ShowMysticEnchant(buildEnchant.Enchant)
				 send new toast
			end
		end
	end)
end]]--
