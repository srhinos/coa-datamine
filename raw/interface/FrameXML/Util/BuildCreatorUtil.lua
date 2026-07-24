BuildCreatorUtil = CreateFromMixins(CallbackRegistryMixin)
CallbackRegistryMixin.OnLoad(BuildCreatorUtil)

BuildCreatorUtil:GenerateCallbackEvents({
	"OnEditorSpellsChanged",
})

BuildCreatorUtil.DescriptionSection = {
	Overview = "OVERVIEW",
	SpellsAndTalents = "SPELLS_AND_TALENTS",
	MysticEnchants = "MYSTIC_ENCHANTS",
	ProsAndCons = "PROS_AND_CONS",
	Itemization = "ITEMIZATION",
	Equipment = "EQUIPMENT",
	Rotation = "ROTATION",
	Consumables = "CONSUMABLES",
	Macros = "MACROS",
	WeakAuras = "WEAKAURAS",
	Notes = "NOTES",
}
BuildCreatorUtil.DescriptionSectionInverted = table.invert(BuildCreatorUtil.DescriptionSection)

BuildCreatorUtil.PickingMode = {
	Spells = 1,
	Enchants = 2,
}

BuildCreatorUtil.RatingQuality = {
	[0] = Enum.ItemQuality.Common,
	[5] = Enum.ItemQuality.Uncommon,
	[50] = Enum.ItemQuality.Rare,
	[250] = Enum.ItemQuality.Epic,
	[500] = Enum.ItemQuality.Legendary,
	[1000] = Enum.ItemQuality.Artifact,
}

BuildCreatorUtil.DifficultyAtlas = {
	[Enum.BuildDifficulty.Standard] = "professions-icon-quality-tier1",
	[Enum.BuildDifficulty.Intermediate] = "professions-icon-quality-tier2",
	[Enum.BuildDifficulty.Advanced] = "professions-icon-quality-tier3",
	[Enum.BuildDifficulty.Expert] = "professions-icon-quality-tier4",
	[Enum.BuildDifficulty.Impossible] = "professions-icon-quality-tier5",
}

BuildCreatorUtil.DifficultyColors = {
	[Enum.BuildDifficulty.Standard] = DIFFICULTY_COLORS[1],
	[Enum.BuildDifficulty.Intermediate] = DIFFICULTY_COLORS[2],
	[Enum.BuildDifficulty.Advanced] = DIFFICULTY_COLORS[3],
	[Enum.BuildDifficulty.Expert] = DIFFICULTY_COLORS[4],
	[Enum.BuildDifficulty.Impossible] = DIFFICULTY_COLORS[5],
}

local currentPickingMode, currentPickLevel

function BuildCreatorUtil.GetParentCategory(category)
	return Enum.BuildSubCategory[category]
end

function BuildCreatorUtil.GetSubCategories(category)
	local subCategories = {}
	for subCategory, parentCategory in pairs(Enum.BuildSubCategory) do
		if parentCategory == category then
			tinsert(subCategories, subCategory)
		end
	end
	return subCategories
end

function BuildCreatorUtil.GetBuildBestExpansion(build)
	local expansion = Enum.Expansion.Vanilla
	if not build.Spells then
		return expansion
	end
	
	-- since spells are sorted by level, we can just check the last spell.
	local lastSpell = build.Spells[#build.Spells]
	if lastSpell then
		if lastSpell.Level > 70 then
			expansion = Enum.Expansion.WoTLK
		elseif lastSpell.Level > 60 then
			expansion = Enum.Expansion.TBC
		end
	end
	
	return expansion
end

function BuildCreatorUtil.ConvertBuildRoleToLFGRole(role)
	role = Enum.BuildRoles[role]
	if role then
		return role
	end
end

function BuildCreatorUtil.ConvertLFGRoleToBuildRole(role)
	for buildRole, lfgRole in pairs(Enum.BuildRoles) do
		if lfgRole == role then
			return buildRole
		end
	end
end

function BuildCreatorUtil.UnpackDescription(description)
	local sections = {}
	for section in string.gmatch(description, "###%s*([^#]*)") do
		if section then
			local header, text = string.match(section, "^([^\n]*)[\n]?(.*)[\n]*")
			if BuildCreatorUtil.DescriptionSectionInverted[header] then
				text = text:gsub("{HT}", "#")
				tinsert(sections, { header = header, text = text })
			end
		end
	end

	if #sections == 0 then
		-- no sections found, so just dump everything into overview.
		description = description:gsub("{HT}", "#")
		tinsert(sections, { header = BuildCreatorUtil.DescriptionSection.Overview, text = description })
	end
	
	return sections
end

function BuildCreatorUtil.UnpackDescriptionByKeys(description)
	local sections = {}
	for section in string.gmatch(description, "###%s*([^#]*)") do
		if section then
			local header, text = string.match(section, "^([^\n]*)[\n]?(.*)[\n]*")
			if  BuildCreatorUtil.DescriptionSectionInverted[header] then
				text = text:gsub("{HT}", "#")
				sections[header] = text
			end
		end
	end

	if not next(sections) then
		-- no sections found, so just dump everything into overview.
		description = description:gsub("{HT}", "#")
		sections[BuildCreatorUtil.DescriptionSection.Overview] = description
	end

	return sections
end

function BuildCreatorUtil.GetOverviewFromDescription(description)
	local sections = BuildCreatorUtil.UnpackDescriptionByKeys(description)
	local overview = sections[BuildCreatorUtil.DescriptionSection.Overview]
	return overview or ""
end

function BuildCreatorUtil.GetPreviewSpellIndexes(spells)
	local coreSpells = {}
	for i, spell in ipairs(spells) do
		if spell.IsCoreAbility and CharacterAdvancementUtil.GetIDBySpellID(spell.Spell) then
			tinsert(coreSpells, i)
			if #coreSpells >= 4 then
				break
			end
		end
	end

	if #coreSpells == 0 then
		for i, spell in ipairs(spells) do
			if CharacterAdvancementUtil.GetIDBySpellID(spell.Spell) then
				tinsert(coreSpells, i)
				if #coreSpells >= 4 then
					break
				end
			end
		end
	end
	
	return coreSpells
end

function BuildCreatorUtil.GetActiveBuildID()
	local specID = SpecializationUtil.GetActiveSpecialization()
	local activeBuild = C_BuildCreator.GetActiveBuild(specID)
	return not string.isNilOrEmpty(activeBuild) and activeBuild
end

function BuildCreatorUtil.GetDraftedBuildID()
	local draftedBuildID = C_BuildDraft.GetDraftedBuild()
	return not string.isNilOrEmpty(draftedBuildID) and draftedBuildID
end

function BuildCreatorUtil.IsActiveBuildID(buildID)
	return BuildCreatorUtil.GetActiveBuildID() == buildID
end

function BuildCreatorUtil.IsDraftedBuildID(buildID)
	return BuildCreatorUtil.GetDraftedBuildID() == buildID
end

function BuildCreatorUtil.GetSpellsByClass(build, filterCore, filterOptimal, filterSynergistic, filterEmpowering)
	local spellsByClass = {}
	local count = 0
	for _, spell in ipairs(build.Spells) do
		local class, spec = C_CharacterAdvancement.GetClassInfo(spell.Spell)
		class = class and CharacterAdvancementUtil.GetClassFileByDBC(class)
		spec = spec and CharacterAdvancementUtil.GetSpecFileByDBC(spec)

		local filterCheck = true
		local spellData = C_BuildCreator.GetSpell(build.ID, spell.Spell)
		
		if spellData then
			if not filterCore and spellData.IsCoreAbility then
				filterCheck = false
			end

			if not filterOptimal and spellData.IsOptimalAbility then
				filterCheck = false
			end
			
			if not filterEmpowering and spellData.IsEmpoweringAbility then
				filterCheck = false
			end

			if not filterSynergistic and spellData.IsSynergisticAbility then
				filterCheck = false
			end
		end

		if class and filterCheck then
			if not spellsByClass[class] then
				spellsByClass[class] = {}
			end
			if not spellsByClass[class][spec] then
				spellsByClass[class][spec] = {}
				count = count + 1
			end

			-- merge talents together if they're all the same level!
			if C_CharacterAdvancement.IsTalentSpellID(spell.Spell) then
				local talentID = C_CharacterAdvancement.GetInternalID(spell.Spell)
				local found = false
				local foundRank
				for _, talentSpell in ipairs(spellsByClass[class][spec]) do
					if talentSpell.TalentID == talentID then
						if talentSpell.Level ~= spell.Level then
							foundRank = talentSpell.TalentRank
						else
							talentSpell.TalentRank = talentSpell.TalentRank + 1
							found = true
							break
						end
					end
				end

				if not found then
					spell.TalentRank = (foundRank and foundRank + 1) or 1
					spell.TalentID = talentID
					tinsert(spellsByClass[class][spec], spell)
					count = count + 1
				end
			else -- spells are fine
				tinsert(spellsByClass[class][spec], spell)
				count = count + 1
			end
		end
	end
	return spellsByClass, count
end


function BuildCreatorUtil.GetSpellsByLevel(build)
	local spellsByLevel = {}
	local talentRanks = {}
	local count, maxLevel = 0, 1
	for _, spell in ipairs(build.Spells) do
		if spell.Level > maxLevel then
			maxLevel = spell.Level
		end
		if not spellsByLevel[spell.Level] then
			spellsByLevel[spell.Level] = {}
			count = count + 1
		end
		-- merge talents together if they're all the same level!
		if C_CharacterAdvancement.IsTalentSpellID(spell.Spell) then
			local talentID = C_CharacterAdvancement.GetInternalID(spell.Spell)
			if not talentRanks[talentID] then
				talentRanks[talentID] = 1
			else
				talentRanks[talentID] = talentRanks[talentID] + 1
			end
			
			spell.TalentID = talentID
			spell.TalentRank = talentRanks[talentID]
		end
		tinsert(spellsByLevel[spell.Level], spell)
		count = count + 1
	end
	return spellsByLevel, count, maxLevel
end

function BuildCreatorUtil.GetLevelingEditorSpells(build, noAE)
	local spellsByLevel = {}
	local talentRanks = {}
	local maxLevel = 80
	local count = 0
	for i = 1, 80 do
		local spells = {}
		spellsByLevel[i] = spells
		local _, aeRemaining, _, teRemaining = C_BuildEditor.GetEssenceForLevel(i)
		spells.AERemaining = noAE and -1 or aeRemaining
		spells.TERemaining = teRemaining

		if spells.AERemaining > 0 or spells.TERemaining > 0 then
			count = count + 1
			spells.CanAdd = true
			spells.HasHeader = true
			count = count + 1
		end
	end

	for _, spell in ipairs(build.Spells) do
		-- merge talents together if they're all the same level!
		if C_CharacterAdvancement.IsTalentSpellID(spell.Spell) then
			local talentID = C_CharacterAdvancement.GetInternalID(spell.Spell)
			if not talentRanks[talentID] then
				talentRanks[talentID] = 1
			else
				talentRanks[talentID] = talentRanks[talentID] + 1
			end

			spell.TalentID = talentID
			spell.TalentRank = talentRanks[talentID]
		end

		tinsert(spellsByLevel[spell.Level], spell)

		if not spellsByLevel[spell.Level].HasHeader then
			-- if a section has no add button
			-- but has spells, we still need a header
			spellsByLevel[spell.Level].HasHeader = true
			count = count + 1
		end

		count = count + 1
	end
	return spellsByLevel, count, maxLevel
end

function BuildCreatorUtil.SetPickMode(pickMode, level)
	currentPickingMode = pickMode
	currentPickLevel = level
	
	StaticPopup_Hide("BUILD_CREATOR_FINISH_PICKING_SPELLS")
	StaticPopup_Hide("BUILD_CREATOR_FINISH_PICKING_ENCHANTS")
end

function BuildCreatorUtil.GetPickLevel()
	return currentPickLevel
end

function BuildCreatorUtil.IsPickingSpells()
	return currentPickingMode == BuildCreatorUtil.PickingMode.Spells
end

function BuildCreatorUtil.IsPickingEnchants()
	return currentPickingMode == BuildCreatorUtil.PickingMode.Enchants
end

function BuildCreatorUtil.FormatProsAndCons(text)
	text = text and text:gsub("^([%+%-])%s*([^\n%+%-]+)", function(sign, substr)
		if sign == "+" then
			substr = GREEN_FONT_COLOR:WrapText("+"..substr)
		elseif sign == "-" then
			substr = RED_FONT_COLOR:WrapText("-"..substr)
		end
		return substr
	end)
	
	return text or ""
end

function BuildCreatorUtil.CreateSpellInfo(spellID, level, isCore, comment, flags)
	local spell = {
		Spell = spellID,
		Level = level or GetMaxLevel(),
		IsCoreAbility = isCore or false,
		Comment = comment or "",
		Flags = flags or 0,
	}
	return spell
end

function BuildCreatorUtil.CreateEnchantInfo(enchantID, stacks, level, comment)
	local enchant = {
		Enchant = enchantID,
		Stacks = stacks or 1,
		Level = level or GetMaxLevel(),
		Comment = comment or "",
	}
	return enchant
end

function BuildCreatorUtil.GetCurrentTalentRank(entryID)
	local entry = C_CharacterAdvancement.GetEntryByInternalID(entryID)
	local rank
	if entry and (entry.Type == "Talent" or entry.Type == "TalentAbility") then
		for index, spell in ipairs(entry.Spells) do
			if not C_BuildEditor.DoesBuildHaveSpellID(spell) then
				return rank
			else
				rank = index
			end
		end
	end
	
	return rank
end

function BuildCreatorUtil.GetNextTalentSpellID(spellID)
	local entry = C_CharacterAdvancement.GetEntryBySpellID(spellID)

	if entry and (entry.Type == "Talent" or entry.Type == "TalentAbility") then
		for _, spell in ipairs(entry.Spells) do
			if not C_BuildEditor.DoesBuildHaveSpellID(spell) then
				return spell
			end
		end
	end
	
	return spellID
end

function BuildCreatorUtil.UpdatePendingBuild()
	if BuildCreatorFrame then
		BuildCreatorFrame.EditableBuildViewPanel:UpdatePendingBuild()
	end
end

function BuildCreatorUtil.ResetPendingBuild()
	if BuildCreatorFrame then
		BuildCreatorFrame.EditableBuildViewPanel:UpdatePendingBuild(true)
	end
end

local HeldSpellFrame
function BuildCreatorUtil.PickupSpell(spell)
	if not HeldSpellFrame then
		HeldSpellFrame = CreateFrame("Button", "BuildCreatorHeldSpellFrame", UIParent, "BuildSpellTemplate")
		HeldSpellFrame:SetFrameLevel(500)
		HeldSpellFrame:EnableMouse(false)
		HeldSpellFrame:SetFrameStrata("FULLSCREEN")

		HeldSpellFrame:SetScript("OnUpdate", function(self)
			local x, y = GetScaledCursorPosition()
			self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
		end)

		HeldSpellFrame.XIcon = HeldSpellFrame:CreateTexture(nil, "OVERLAY")
		HeldSpellFrame.XIcon:SetAtlas("common-icon-redx", Const.TextureKit.IgnoreAtlasSize)
		HeldSpellFrame.XIcon:SetPoint("CENTER", -16, 0)
		HeldSpellFrame.XIcon:SetSize(32, 32)
	end

	if spell.TalentID then
		HeldSpellFrame:SetTalent(spell)
	else
		HeldSpellFrame:SetSpell(spell)
	end

	HeldSpellFrame:SetAlpha(0.8)
	HeldSpellFrame:Show()
end

function BuildCreatorUtil.CheckHeldSpellPlacement(level)
	if HeldSpellFrame then
		local spell = BuildCreatorUtil.GetHeldSpell()
		if not level then
			HeldSpellFrame:SetAlpha(0.5)
			HeldSpellFrame.XIcon:Hide()
		elseif spell and C_BuildEditor.CanSetSpellLevel(spell.Spell, level) then
			HeldSpellFrame:SetAlpha(0.9)
			HeldSpellFrame.XIcon:Hide()
		else
			HeldSpellFrame:SetAlpha(0.5)
			HeldSpellFrame.XIcon:Show()
		end
	end
end

function BuildCreatorUtil.ReleaseHeldSpell()
	if HeldSpellFrame then
		HeldSpellFrame:Hide()
		HeldSpellFrame.info = nil
	end
end

function BuildCreatorUtil.GetHeldSpell()
	return HeldSpellFrame and HeldSpellFrame.info
end

function BuildCreatorUtil.PlaceHeldSpellAtLevel(level)
	local spell = BuildCreatorUtil.GetHeldSpell()
	if spell and level then
		if C_BuildEditor.CanSetSpellLevel(spell.Spell, level) then
			C_BuildEditor.SetSpellLevel(spell.Spell, level)
			if BuildCreatorFrame then
				BuildCreatorUtil.UpdatePendingBuild()
			end
			BuildCreatorUtil.ReleaseHeldSpell()
		end
	end
end

function BuildCreatorUtil.GetRatingQuality(rating)
	local ratingQuality = 0
	for minRating, quality in pairs(BuildCreatorUtil.RatingQuality) do
		if rating >= minRating and quality > ratingQuality then
			ratingQuality = quality
		end
	end

	return ratingQuality
end 

function BuildCreatorUtil.ToggleBuildActive(buildID, category, autoLearn)
    if BuildCreatorUtil.IsActiveBuildID(buildID) then
    	if BuildCreatorUtil.IsDraftedBuildID(buildID) then
    		-- deactivate current build in build draft 
    		StaticPopup_Show("CONFIRM_DEACTIVATE_BUILD_DRAFT", nil, nil, buildID)
    	else
    		-- deactivate build not in build draft
    		StaticPopup_Show("CONFIRM_DEACTIVATE_BUILD", nil, nil, buildID)
    	end
    else
    	-- build draft check
    	if BuildCreatorUtil.IsCategoryBuildDraft(category) then
            -- activating build draft build
    		if C_Player:GetLevel() >= 10 then
    			-- no rewards
    			StaticPopup_Show("BUILD_DRAFT_ACTIVATE_CONFIRM_NO_REWARDS", nil, nil, { buildID, autoLearn, autoLearn })
    		else
    			-- will get rewards
    			StaticPopup_Show("BUILD_DRAFT_ACTIVATE_CONFIRM", nil, nil, { buildID, autoLearn, autoLearn })
    		end
    	else
            -- activating non build draft build
            if BuildCreatorUtil.GetDraftedBuildID() then
                -- activate build, not in build draft
                StaticPopup_Show("CONFIRM_ACTIVATE_BUILD", nil, nil, { buildID, autoLearn, autoLearn })
            else
                -- activate build while in build draft
                StaticPopup_Show("CONFIRM_ACTIVATE_BUILD_DEACTIVATE_BUILD_DRAFT", nil, nil, { buildID, autoLearn, autoLearn })
            end
    	end
    end
end

function BuildCreatorUtil.IsCategoryBuildDraft(category)
	return category == Enum.BuildCategory.BuildDraft or category == Enum.BuildCategory.BuildDraftEndGamePvE or category == Enum.BuildCategory.BuildDraftEndGamePvP
end 

function BuildCreatorUtil.ContinueOnLoad(buildID, callback)
	BuildCreator_LoadUI()
	if BuildCreatorFrame then
		return BuildCreatorFrame:ContinueOnLoad(buildID, callback)
	end
end

function BuildCreatorUtil.RefreshFinishPickingPopup()
	local _, aeRemaining, _, teRemaining = C_BuildEditor.GetEssenceForLevel(BuildCreatorUtil.GetPickLevel())

	local show = false
	if not StaticPopup_FindVisible("BUILD_CREATOR_FINISH_PICKING_SPELLS") then
		show = true
	end

	if C_Player:IsDefaultClass() then
		local teItem = Item:CreateFromID(ItemData.TALENT_ESSENCE)
		local teText = teRemaining .. " " .. teItem:GetIconLink(22)
		if show then
			StaticPopup_Show("BUILD_CREATOR_FINISH_PICKING_SPELLS", teText, "")
		else
			StaticPopup_UpdateText("BUILD_CREATOR_FINISH_PICKING_SPELLS", teText, "")
		end
	else
		local aeItem = Item:CreateFromID(ItemData.ABILITY_ESSENCE)
		local aeText = aeRemaining .. " " .. aeItem:GetIconLink(22)
		local teItem = Item:CreateFromID(ItemData.TALENT_ESSENCE)
		local teText = teRemaining .. " " .. teItem:GetIconLink(22)
		if show then
			StaticPopup_Show("BUILD_CREATOR_FINISH_PICKING_SPELLS", aeText, teText)
		else
			StaticPopup_UpdateText("BUILD_CREATOR_FINISH_PICKING_SPELLS", aeText, teText)
		end
	end
end 

function BuildCreatorUtil.EditorSpellsChanged(preserveFilter)
	BuildCreatorUtil:TriggerEvent("OnEditorSpellsChanged", preserveFilter)
end 

function BuildCreatorUtil.GetBuildLink(build)
	if build then
		return "|cff00ff96|Hcabuild:"..build.ID.."|h["..build.Name.."]|h|r"
	end
end 

local pendingBuildID
function BuildCreatorUtil.ImportPendingBuildID(buildID)
	C_CharacterAdvancement.ClearPendingBuild(Const.CharacterAdvancement.ClearEverything)
	C_CharacterAdvancement.ImportPendingBuildID(buildID)
	pendingBuildID = buildID
end

function BuildCreatorUtil.GetPendingBuildID()
	return pendingBuildID
end 

function BuildCreatorUtil.ClearPendingBuildID()
	pendingBuildID = nil
end 