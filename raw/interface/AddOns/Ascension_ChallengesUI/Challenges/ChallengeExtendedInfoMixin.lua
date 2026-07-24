ChallengeExtendedInfoMixin = {}

local function ResetAura(pool, frame)
	frame.tooltipTitle = nil
	frame.tooltipText = nil
	frame:Hide()
	frame:SetParent(UIParent)
	frame:ClearAllPoints()
end

local SpellIconPool = CreateFramePool("BUTTON", UIParent, "ChallengesSpellIconTemplate", ResetAura)

local function GetLeaderboardClassInfo(playerClass)
	local class = CLASS_ENUM_TO_CLASS_FILE[playerClass] or playerClass and playerClass:sub(7)
	local classColor = RAID_CLASS_COLORS[class] or HIGHLIGHT_FONT_COLOR
	local className = LOCALIZED_CLASS_NAMES_MALE[class] or class or UNKNOWN
	return class, classColor, className
end

function ChallengeExtendedInfoMixin:OnLoad()
	self.data = {}
	self.SpellIconPool = SpellIconPool
	self.InfoScroll:SetCanSelect(false)
	self.LeaderboardScroll:SetCanSelect(false)

	local numResultsFunction = function()
		return #self.data
	end
	self.InfoScroll:SetGetNumResultsFunction(numResultsFunction)
	self.LeaderboardScroll:SetGetNumResultsFunction(numResultsFunction)
end

function ChallengeExtendedInfoMixin:SetTitle(text)
	self.Title:SetText(text)
end

function ChallengeExtendedInfoMixin:SetFormattedTitle(text, ...)
	self.Title:SetFormattedText(text, ...)
end

function ChallengeExtendedInfoMixin:SetSubText(text)
	self.SubText:SetText(text)
end

function ChallengeExtendedInfoMixin:SetFormattedSubText(text, ...)
	self.SubText:SetFormattedText(text)
end

function ChallengeExtendedInfoMixin:ReleasePools()
	self.SpellIconPool:ReleaseAll()
end

function ChallengeExtendedInfoMixin:ShowDescription()
	self.Description:Show()
	self.InfoScroll:Hide()
	self.LeaderboardScroll:Hide()
end

function ChallengeExtendedInfoMixin:ShowInfoScroll()
	self.InfoScroll:Show()
	self.LeaderboardScroll:Hide()
	self.Description:Hide()
	if not self.InfoScroll:IsInitialized() then
		self.InfoScroll:SetTemplate("ChallengeInfoLineTemplate")
		HybridScrollFrame_SetDoNotHideScrollBar(self.InfoScroll.ScrollFrame, false)
	end
	self.InfoScroll:ScrollToBegin()
end

function ChallengeExtendedInfoMixin:ShowLeaderboardScroll()
	self.LeaderboardScroll:Show()
	self.Description:Hide()
	self.InfoScroll:Hide()
	if not self.LeaderboardScroll:IsInitialized() then
		self.LeaderboardScroll:SetTemplate("ChallengeLeaderboardEntryTemplate")
		HybridScrollFrame_SetDoNotHideScrollBar(self.LeaderboardScroll.ScrollFrame, false)
	end
	self.LeaderboardScroll:ScrollToBegin()
end

function ChallengeExtendedInfoMixin:HideAllScrolls()
	self.LeaderboardScroll:Hide()
	self.Description:Hide()
	self.InfoScroll:Hide()
end

function ChallengeExtendedInfoMixin:RefreshScroll()
	if self.LeaderboardScroll:IsShown() then
		self.LeaderboardScroll:RefreshScrollFrame()
	elseif self.InfoScroll:IsShown() then
		self.InfoScroll:RefreshScrollFrame()
	end
end

function ChallengeExtendedInfoMixin:ShowAboutTab(about)
	self:ReleasePools()
	self:SetSubText(CHALLENGES_ABOUT)
	self.Description:SetText(about)
	self:ShowDescription()
end

local function SetupSpellIcon(self, x, y, spellID, isPvE, hasType)
	local spellIcon = self.SpellIconPool:Acquire()
	spellIcon:SetParent(self)
	spellIcon:SetPoint("TOPLEFT", self.SubText, "BOTTOMLEFT", x, y)
	spellIcon:SetSpell(spellID)
	spellIcon:SetBorderAtlas("GarrMission_WeakEncounterAbilityBorder")
	spellIcon:SetBorderSize(72, 72)
	spellIcon.AuraType:Show()
	if hasType then
		spellIcon.AuraType.Icon:SetAtlas(isPvE and "questbonusobjective" or "crossedflags", Const.TextureKit.IgnoreAtlasSize)
		spellIcon.AuraType.tooltipTitle = isPvE and CHALLENGES_PVE_AURA or CHALLENGES_PVP_AURA
		spellIcon.AuraType.tooltipText = isPvE and CHALLENGES_PVE_AURA_DESC or CHALLENGES_PVP_AURA_DESC
	else
		spellIcon.AuraType.Icon:SetAtlas("honorsystem-icon-bonus", Const.TextureKit.IgnoreAtlasSize)
		spellIcon.AuraType.tooltipTitle = CHALLENGES_PVPVE_AURA
		spellIcon.AuraType.tooltipText = CHALLENGES_PVPVE_AURA_DESC
	end
	spellIcon:Show()
	
	return spellIcon
end

local function SetupModifierIcon(self, x, y, tooltipTitle, tooltipText, icon)
	local spellIcon = self.SpellIconPool:Acquire()
	spellIcon:SetParent(self)
	spellIcon:SetPoint("TOPLEFT", self.SubText, "BOTTOMLEFT", x, y)
	spellIcon:SetSpell()
	spellIcon:SetIcon("Interface\\Icons\\"..icon)
	spellIcon.tooltipTitle = tooltipTitle
	spellIcon.tooltipText = tooltipText
	spellIcon:SetBorderAtlas("GarrMission_WeakEncounterAbilityBorder")
	spellIcon:SetBorderSize(72, 72)
	spellIcon.AuraType:Hide()
	spellIcon:Show()

	return spellIcon
end

function ChallengeExtendedInfoMixin:ShowAurasTab(auras, modifiers)
	self:ReleasePools()
	self:SetSubText(CHALLENGES_AURAS)
	self:HideAllScrolls()

	local x, y = 4, -6
	local pveID, pvpID, sameSpell, spellIcon
	for _, aura in ipairs(auras) do
		pveID = aura.PvESpellID ~= 0 and aura.PvESpellID
		pvpID = aura.PvPSpellID ~= 0 and aura.PvPSpellID

		if not pveID and not pvpID then
			return
		end
		
		sameSpell = pveID == pvpID

		if pveID then
			spellIcon = SetupSpellIcon(self, x, y, pveID, true, not sameSpell)
			 x = x + spellIcon:GetWidth() + 10
			if x > 360 then
				x = 4
				y = y - spellIcon:GetHeight() - 10
			end
		end

		if not sameSpell and pvpID then
			spellIcon = SetupSpellIcon(self, x, y, pvpID, false, true)
			x = x + spellIcon:GetWidth() + 10
			if x > 360 then
				x = 4
				y = y - spellIcon:GetHeight() - 10
			end
		end
	end

	if modifiers then
		local tooltipTitle, tooltipText, icon
		for modifier, values in pairs(modifiers) do
			tooltipTitle, tooltipText, icon = C_Challenge.GetModifierLocalization(modifier)
			tooltipText = tooltipText:gsub("{([^}]*)}", function(valueIndex)
				return values[valueIndex] or valueIndex
			end)
			spellIcon = SetupModifierIcon(self, x, y, tooltipTitle, tooltipText, icon)
			x = x + spellIcon:GetWidth() + 10
			if x > 360 then
				x = 4
				y = y - spellIcon:GetHeight() - 10
			end
		end
	end
end

function ChallengeExtendedInfoMixin:ShowLeaderboard(challengeID, level)
	self:ReleasePools()
	self:SetSubText(CHALLENGES_LEADERBOARD)
	self.type = "leaderboard"
	local entries
	if level then
		entries = C_Challenge.GetChallengeCompletions(challengeID, level, 50)
	else
		entries = C_TrialCreator.GetTrialCompletions(challengeID, 50)
	end
	self.data = entries or {}
	self:ShowLeaderboardScroll()
	self:RefreshScroll()
end

function ChallengeExtendedInfoMixin:SetLeaderboardScrollItem(index, data, scrollItem)
	scrollItem.Rank:SetText(index)
	local rankColor = LEADERBOARD_RANK_COLORS[index] or HIGHLIGHT_FONT_COLOR
	scrollItem.Rank:SetTextColor(rankColor:GetRGB())

	local hasLeaderPosition = index <= #LEADERBOARD_MEDAL_TEXTURES_SMALL
	if hasLeaderPosition then
		scrollItem.Medal:Show()
		scrollItem.Medal:SetTexture(LEADERBOARD_MEDAL_TEXTURES_SMALL[index])
		scrollItem.Glow:Show()
		scrollItem.Glow.Animation:Play()
	else
		scrollItem.Medal:Hide()
		scrollItem.Glow:Hide()
		scrollItem.Glow.Animation:Stop()
	end
	scrollItem.Medal:SetShown(hasLeaderPosition)
	scrollItem.Medal:SetTexture(LEADERBOARD_MEDAL_TEXTURES_SMALL[index])
	scrollItem.Glow:SetShown(hasLeaderPosition)

	if #data == 1 then -- single player
		local player = data[1]
		local class, classColor, className = GetLeaderboardClassInfo(player.PlayerClass)
		local gender = player.PlayerGender:sub(8)
		local race = player.PlayerRace:sub(6)
		if race == "UNDEAD_PLAYER" then
			race = "SCOURGE"
		end
		local coords = RACE_ICON_TCOORDS[race.."_"..gender]
		scrollItem.Icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CHARACTERCREATE-RACES_Round")
		scrollItem.Icon:SetTexCoord(unpack(coords))

		scrollItem.Name:SetText(classColor:WrapText(player.PlayerName))
		scrollItem.Class:SetText(classColor:WrapText(className))


		local duration = SecondsToTime(player.CompleteTime - player.StartTime, false, false, 4)
		scrollItem.Time:SetFormattedText(CHALLENGES_TIME, duration)

		local dateString = date(CHALLENGE_FAILED_AT_TIME, player.CompleteTime)
		scrollItem.Date:SetFormattedText(CHALLENGES_DATE, dateString)

		scrollItem.tooltipTitle = nil
		scrollItem.tooltipText = nil
		-- end single player
	else -- multiple players
		scrollItem.Icon:SetAtlas("class-round-hero", Const.TextureKit.IgnoreAtlasSize)

		scrollItem.Name:SetFormattedText(NORMAL_FONT_COLOR:WrapText(CHALLENGE_MULTIPLE_LEADERBOARD_PLAYERS), #data)
		scrollItem.Class:SetText("")

		local duration = SecondsToTime(data[1].CompleteTime - data[1].StartTime, false, false, 4)
		scrollItem.Time:SetFormattedText(CHALLENGES_TIME, duration)

		local dateString = date(CHALLENGE_FAILED_AT_TIME, data[1].CompleteTime)
		scrollItem.Date:SetFormattedText(CHALLENGES_DATE, dateString)
		
		scrollItem.tooltipTitle = CHALLENGE_COMPLETED_BY
		scrollItem.tooltipText = nil
		for i, player in ipairs(data) do
			local _, classColor = GetLeaderboardClassInfo(player.PlayerClass)
			local name = i .. ". " .. classColor:WrapText(player.PlayerName)
			if scrollItem.tooltipText then
				scrollItem.tooltipText = scrollItem.tooltipText.."\n"..name
			else
				scrollItem.tooltipText = name
			end
		end
		-- end multiple players
	end
end

function ChallengeExtendedInfoMixin:ShowRestrictionsTab(restrictions)
	self:ReleasePools()
	self:SetSubText(CHALLENGES_RESTRICTIONS)
	self.data = restrictions
	self.type = "restriction"
	self:ShowInfoScroll()
	self:RefreshScroll()
end

local function FormatRequirementValues(data)
	local value1, value2, value3 = data.ConditionValue1, data.ConditionValue2, data.ConditionValue3

	if data.ConditionType == "CHALLENGE_CONDITIONS_TYPE_COMPLETE_CHALLENGE" then
		local challengeName = C_Challenge.GetChallengeInfo(value1).Name
		value1 = challengeName
	elseif data.ConditionType == "CHALLENGE_CONDITIONS_TYPE_COMPLETE_CHALLENGE_GROUP_COUNT" then
		local challenges = C_Challenge.GetChallengesWithGroupID(value1)
		value1 = nil
		for _, challenge in ipairs(challenges) do
			local challengeName = challenge.Name .. " (level: " .. value2 .. ")"
			if value1 then
				value1 = value1.."\n"..challengeName
			else
				value1 = challengeName
			end
		end
	end
	return value1, value2, value3
end

function ChallengeExtendedInfoMixin:ShowRequirementsTab(requirements)
	self:ReleasePools()
	self:SetSubText(CHALLENGES_REQUIREMENTS)
	self.data = requirements
	self.type = "requirement"
	self:ShowInfoScroll()
	self:RefreshScroll()
end

function ChallengeExtendedInfoMixin:SetRequirementScrollItem(data, scrollItem)
	local requirement = data.ConditionType
	local value1, value2, value3 = FormatRequirementValues(data)
	local name, description, negativeName, negativeDescription = C_Challenge.GetConditionLocalization(requirement)
	if data.NegativeCondition then
		scrollItem:SetFormattedText(negativeName or requirement, value1, value2, value3)
		scrollItem.tooltipTitle = format(negativeName or requirement, value1, value2, value3)
		scrollItem.tooltipText = format(negativeDescription or "", value1, value2, value3)
	else
		scrollItem:SetFormattedText(name or requirement, value1, value2, value3)
		scrollItem.tooltipTitle = format(name or requirement, value1, value2, value3)
		scrollItem.tooltipText = format(description or "", value1, value2, value3)
	end

	if data.ConditionMet then
		scrollItem:GetFontString():SetTextColor(GREEN_FONT_COLOR:GetRGB())
	else
		scrollItem:GetFontString():SetTextColor(RED_FONT_COLOR:GetRGB())
	end
end

function ChallengeExtendedInfoMixin:SetRestrictionScrollItem(data, scrollItem)
	local name, description = C_Challenge.GetRuleLocalization(data)
	scrollItem:SetText(name or data)
	scrollItem.tooltipTitle = name or data
	scrollItem.tooltipText = description

	if C_Challenge.HasBrokenChallengeRule(data) then
		scrollItem:GetFontString():SetTextColor(RED_FONT_COLOR:GetRGB())
	else
		scrollItem:GetFontString():SetTextColor(GREEN_FONT_COLOR:GetRGB())
	end
end

function ChallengeExtendedInfoMixin:SetScrollItem(index, scrollItem)
	local data = self.data[index]
	-- requirements
	if self.type == "leaderboard" then
		self:SetLeaderboardScrollItem(index, data, scrollItem)
		return true
	elseif self.type == "requirement" then
		self:SetRequirementScrollItem(data, scrollItem)
		return true
	-- restrictions 
	elseif self.type == "restriction" then
		self:SetRestrictionScrollItem(data, scrollItem)
		return true
	end
	return false
end
